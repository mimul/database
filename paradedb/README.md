# ParadeDB 한글 전문 검색 벤치마크

ParadeDB의 BM25 검색 엔진(pg_search)이 한글 텍스트에 대해 PostgreSQL 표준의 검색 기법에 비해 어느 정도 유효  한지를 검증에 대한 내용입니다.

## 환경

| 항목         | 설명                                    |
| ---------- | --------------------------------------- |
| ParadeDB   | paradedb/paradedb:latest                |
| PostgreSQL | 17.7 (aarch64)                          |
| pg_search  | 0.20.10                                 |
| 테스트 데이터 | 한글 논문/기사 등 8,100건                    |
| 실행 환경    | Docker Desktop on macOS (Apple Silicon) |

## 파일 구성

```shell
.
├── compose.yaml      # Docker Compose 설정
├── setup.sql         # 테이블 생성, 테스트 데이터 생성
├── benchmark.sql     # 벤치마크 실행 스크립트
└── README.md         # 이 문서 소개
```

## 사용법

```bash
> brew install --cask docker(앱 설치후 docker 앱을 실행)

# 구동
> docker compose up -d

# 테이블 생성 및 테스트 데이터 생성
> docker exec -i paradedb psql -U paradedb -d paradedb < setup.sql

# 벤치마크 실행
> docker exec -i paradedb psql -U paradedb -d paradedb < benchmark.sql

# 정지
> docker compose down

# 데이터를 포함 삭제
> docker compose down -v
```
