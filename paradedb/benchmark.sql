-- ============================================================
-- ParadeDB 한글 검색
-- ============================================================

\timing on

-- 병렬 작업자를 비활성화하여 정확한 실행 시간을 측정(병렬 작업자의 시작 오버 헤드가 벤치 마크 결과를 왜곡하는 것을 방지)
SET max_parallel_workers_per_gather = 0;

-- ============================================================
-- STEP 1: 인덱스
-- ============================================================

-- 1). ParadeDB BM25 lindera 한글 토크나이저 사용
DROP INDEX IF EXISTS search_idx;
CREATE INDEX search_idx ON articles
USING bm25 (
    id,
    (title::pdb.lindera(korean)),
    (body::pdb.lindera(korean)),
    (category::pdb.lindera(korean))
)
WITH (key_field='id');

-- 2) PostgreSQL GIN 색인(pg_trgm) LIKE 검색 가속화
CREATE EXTENSION IF NOT EXISTS pg_trgm;
DROP INDEX IF EXISTS trgm_title_idx;
DROP INDEX IF EXISTS trgm_body_idx;
CREATE INDEX trgm_title_idx ON articles USING gin (title gin_trgm_ops);
CREATE INDEX trgm_body_idx ON articles USING gin (body gin_trgm_ops);

-- 3) PostgreSQL GIN tsvector 색인(simple 사전 - 한글용 임베디드 사전이 없기 때문에)
DROP INDEX IF EXISTS ts_title_idx;
DROP INDEX IF EXISTS ts_body_idx;
CREATE INDEX ts_title_idx ON articles USING gin (to_tsvector('simple', title));
CREATE INDEX ts_body_idx ON articles USING gin (to_tsvector('simple', body));

-- ANALYZE
ANALYZE articles;

-- ============================================================
-- STEP 2: 토크나이저의 동작 확인
-- ============================================================
\echo '=== lindera(korean) 토크나이저의 동작 확인 ==='
SELECT '차세대반도체'::pdb.lindera(korean)::text[];
SELECT '클라우드입문가이드'::pdb.lindera(korean)::text[];
SELECT '기계학습을활용한이미지인식'::pdb.lindera(korean)::text[];

-- ============================================================
-- STEP 3: 검색 정확도 비교
-- ============================================================

-- -------------------------------------------------------
-- 1) 인공지능 검색
-- -------------------------------------------------------
\echo ''
\echo '========================================='
\echo '1) 인공지능 검색                            '
\echo '========================================='

\echo ''
\echo '--- ParadeDB BM25 검색 ---'
EXPLAIN ANALYZE
SELECT id, title, pdb.score(id) AS score
FROM articles
WHERE title ||| '인공지능' OR body ||| '인공지능'
ORDER BY score DESC
LIMIT 10;

\echo ''
\echo '--- PostgreSQL LIKE 검색 ---'
EXPLAIN ANALYZE
SELECT id, title
FROM articles
WHERE title LIKE '%인공지능%' OR body LIKE '%인공지능%'
LIMIT 10;

\echo ''
\echo '--- PostgreSQL tsvector 검색 ---'
EXPLAIN ANALYZE
SELECT id, title
FROM articles
WHERE to_tsvector('simple', title) @@ to_tsquery('simple', '인공지능')
   OR to_tsvector('simple', body) @@ to_tsquery('simple', '인공지능')
LIMIT 10;

-- -------------------------------------------------------
-- 2) 기계학습 검색
-- -------------------------------------------------------
\echo ''
\echo '========================================='
\echo '2) 기계학습 검색                             '
\echo '========================================='

\echo ''
\echo '--- ParadeDB BM25 검색 ---'
EXPLAIN ANALYZE
SELECT id, title, pdb.score(id) AS score
FROM articles
WHERE title ||| '기계학습' OR body ||| '기계학습'
ORDER BY score DESC
LIMIT 10;

\echo ''
\echo '--- PostgreSQL LIKE 검색 ---'
EXPLAIN ANALYZE
SELECT id, title
FROM articles
WHERE title LIKE '%기계학습%' OR body LIKE '%기계학습%'
LIMIT 10;

\echo ''
\echo '--- PostgreSQL tsvector 검색 ---'
EXPLAIN ANALYZE
SELECT id, title
FROM articles
WHERE to_tsvector('simple', title) @@ to_tsquery('simple', '기계학습')
   OR to_tsvector('simple', body) @@ to_tsquery('simple', '기계학습')
LIMIT 10;

-- -------------------------------------------------------
-- 3) 환경문제 검색
-- -------------------------------------------------------
\echo ''
\echo '========================================='
\echo '3) 환경문제 검색                            '
\echo '========================================='

\echo ''
\echo '--- ParadeDB BM25 검색 ---'
EXPLAIN ANALYZE
SELECT id, title, pdb.score(id) AS score
FROM articles
WHERE title ||| '환경문제' OR body ||| '환경문제'
ORDER BY score DESC
LIMIT 10;

\echo ''
\echo '--- PostgreSQL LIKE 검색 ---'
EXPLAIN ANALYZE
SELECT id, title
FROM articles
WHERE title LIKE '%환경문제%' OR body LIKE '%환경문제%'
LIMIT 10;

\echo ''
\echo '--- PostgreSQL tsvector 검색 ---'
EXPLAIN ANALYZE
SELECT id, title
FROM articles
WHERE to_tsvector('simple', title) @@ to_tsquery('simple', '환경문제')
   OR to_tsvector('simple', body) @@ to_tsquery('simple', '환경문제')
LIMIT 10;

-- -------------------------------------------------------
-- 4) 복합 검색 - 신재생에너지 기술 혁신
-- -------------------------------------------------------
\echo ''
\echo '========================================='
\echo '4) 복합 검색 - 신재생에너지 기술 혁신
\echo '========================================='

\echo ''
\echo '--- ParadeDB BM25검색（AND） ---'
EXPLAIN ANALYZE
SELECT id, title, pdb.score(id) AS score
FROM articles
WHERE body &&& '신재생에너지기술혁신'
ORDER BY score DESC
LIMIT 10;

\echo ''
\echo '--- PostgreSQL LIKE 검색（AND） ---'
EXPLAIN ANALYZE
SELECT id, title
FROM articles
WHERE body LIKE '%신재생에너지%' AND body LIKE '%기술혁신%'
LIMIT 10;

\echo ''
\echo '--- PostgreSQL tsvector 검색(AND) ---'
EXPLAIN ANALYZE
SELECT id, title
FROM articles
WHERE to_tsvector('simple', body) @@ to_tsquery('simple', '신재생에너지')
   AND to_tsvector('simple', body) @@ to_tsquery('simple', '기술혁신')
LIMIT 10;

-- -------------------------------------------------------
-- 5) 형태소 분석의 이점 - 달리기에서 달리다도 검색
-- -------------------------------------------------------
\echo ''
\echo '========================================='
\echo '5) 형태소 분석의 이점 테스트                   '
\echo '========================================='

-- 테스트용 데이터 삽입
INSERT INTO articles (title, body, category) VALUES
('달리기 건강 효과', '매일 달리는 것은 심폐 기능을 강화하고 스트레스를 완화합니다. 달릴 때 느끼는 상쾌감은 러너스 하이라고 불리며 엔돌핀의 분비 때문입니다.', '건강'),
('뇌과학', '실제로 원하는 것에 집중하면 뇌의 필터가 그 목표랑 관련된 기회와 정보를 포착한다. 그리고 내 뇌가 그전까지는 못보고 지나쳤던 기회들을 드디어 발견하게 만든다.', '논문');

\echo ''
\echo '--- ParadeDB BM25: 달리기 검색 ---'
SELECT id, title, pdb.score(id) AS score
FROM articles
WHERE body ||| '달리기'
ORDER BY score DESC
LIMIT 10;

\echo ''
\echo '--- PostgreSQL LIKE: 달리기 검색 ---'
SELECT id, title
FROM articles
WHERE body LIKE '%달리기%'
LIMIT 10;

\echo ''
\echo '--- PostgreSQL LIKE: 달리다로 검색(부분 일치) ---'
SELECT id, title
FROM articles
WHERE body LIKE '%달리다%'
LIMIT 10;

\echo ''
\echo '--- PostgreSQL tsvector 달리기 검색 ---'
EXPLAIN ANALYZE
SELECT id, title
FROM articles
WHERE to_tsvector('simple', title) @@ to_tsquery('simple', '달리기')
LIMIT 10;

-- -------------------------------------------------------
-- 6) 카테고리별 필터 검색
-- -------------------------------------------------------
\echo ''
\echo '========================================='
\echo '6) 카테고리별 필터 검색                       '
\echo '========================================='

\echo ''
\echo '--- ParadeDB BM25: 기술 + AI ---'
EXPLAIN ANALYZE
SELECT id, title, category, pdb.score(id) AS score
FROM articles
WHERE body ||| '인공지능' AND category &&& '기술'
ORDER BY score DESC
LIMIT 10;

\echo ''
\echo '--- PostgreSQL: 기술 + AI ---'
EXPLAIN ANALYZE
SELECT id, title, category
FROM articles
WHERE body LIKE '%인공지능%' AND category = '기술'
LIMIT 10;

-- -------------------------------------------------------
-- 7) 스코어링 및 스니펫
-- -------------------------------------------------------
\echo ''
\echo '========================================='
\echo '7) BM25 스코어링 및 스니펫                    '
\echo '========================================='

\echo ''
\echo '--- ParadeDB: 점수가 있는 검색 결과 ---'
SELECT id, title, pdb.score(id) AS relevance_score
FROM articles
WHERE body ||| '사이버보안'
ORDER BY relevance_score DESC
LIMIT 5;

\echo ''
\echo '--- ParadeDB: 스니펫(하이라이트)이 있는 검색 결과 ---'
SELECT id, title, pdb.snippet(body) AS highlighted_body
FROM articles
WHERE body ||| '블록체인'
ORDER BY pdb.score(id) DESC
LIMIT 5;

-- -------------------------------------------------------
-- 8) 성능 비교(여러 번 실행 평균)
-- -------------------------------------------------------
\echo ''
\echo '========================================='
\echo '8) 성능 비교(반복 실행)                       '
\echo '========================================='

\echo ''
\echo '--- ParadeDB BM25: 디지털 트랜스포메이션 × 5회---'
EXPLAIN ANALYZE SELECT count(*) FROM articles WHERE body ||| '디지털트랜스포메이션';
EXPLAIN ANALYZE SELECT count(*) FROM articles WHERE body ||| '디지털트랜스포메이션';
EXPLAIN ANALYZE SELECT count(*) FROM articles WHERE body ||| '디지털트랜스포메이션';
EXPLAIN ANALYZE SELECT count(*) FROM articles WHERE body ||| '디지털트랜스포메이션';
EXPLAIN ANALYZE SELECT count(*) FROM articles WHERE body ||| '디지털트랜스포메이션';

\echo ''
\echo '--- PostgreSQL LIKE: 디지털 트랜스포메이션 × 5회 ---'
EXPLAIN ANALYZE SELECT count(*) FROM articles WHERE body LIKE '%디지털 트랜스포메이션%';
EXPLAIN ANALYZE SELECT count(*) FROM articles WHERE body LIKE '%디지털 트랜스포메이션%';
EXPLAIN ANALYZE SELECT count(*) FROM articles WHERE body LIKE '%디지털 트랜스포메이션%';
EXPLAIN ANALYZE SELECT count(*) FROM articles WHERE body LIKE '%디지털 트랜스포메이션%';
EXPLAIN ANALYZE SELECT count(*) FROM articles WHERE body LIKE '%디지털 트랜스포메이션%';

\echo ''
\echo '--- ParadeDB tsvector: 디지털트랜스포메이션 × 5회---'
EXPLAIN ANALYZE SELECT count(*) FROM articles WHERE to_tsvector('simple', body) @@ to_tsquery('simple', '디지털 트랜스포메이션');
EXPLAIN ANALYZE SELECT count(*) FROM articles WHERE to_tsvector('simple', body) @@ to_tsquery('simple', '디지털 트랜스포메이션');
EXPLAIN ANALYZE SELECT count(*) FROM articles WHERE to_tsvector('simple', body) @@ to_tsquery('simple', '디지털 트랜스포메이션');
EXPLAIN ANALYZE SELECT count(*) FROM articles WHERE to_tsvector('simple', body) @@ to_tsquery('simple', '디지털 트랜스포메이션');
EXPLAIN ANALYZE SELECT count(*) FROM articles WHERE to_tsvector('simple', body) @@ to_tsquery('simple', '디지털 트랜스포메이션');

-- -------------------------------------------------------
-- 9) Facet Aggregation（BM25 부가 기능）
-- -------------------------------------------------------
\echo ''
\echo '========================================='
\echo '9) Facet Aggregation'
\echo '========================================='

\echo ''
\echo '--- ParadeDB: 기술 검색 + 카테고리별 집계 ---'
SELECT category, count(*) as cnt, avg(pdb.score(id))::numeric(10,4) as avg_score
FROM articles
WHERE body ||| '기술'
GROUP BY category
ORDER BY cnt DESC;

\echo ''
\echo '--- PostgreSQL: 기술 검색 + 카테고리별 집계 ---'
SELECT category, count(*) as cnt
FROM articles
WHERE body LIKE '%기술%'
GROUP BY category
ORDER BY cnt DESC;

\echo ''
\echo '========================================='
\echo '벤치마크 완료                               '
\echo '========================================='
