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
> brew install --cask docker(앱 설치 언되었을 경우 설치 후 docker 앱을 실행)

# 구동
> docker compose up -d

# 테이블 생성 및 테스트 데이터 생성
> docker exec -i paradedb psql -U paradedb -d paradedb < setup.sql

#mecab-ko 이용한 한글 full-text search를 위해서 아래 작업을 수행한다.

> git clone https://bitbucket.org/eunjeon/mecab-ko.git
> cd mecab-ko
> ./configure
> make && make install

> apt install automake libtool -y
> vi /etc/ld.so.conf 
/usr/local/lib

> wget https://bitbucket.org/eunjeon/mecab-ko-dic/downloads/mecab-ko-dic-2.1.1-20180720.tar.gz
> cd mecab-ko-dic/
> ./configure
> make && make install

> echo '아버지가방에들어가신다'|mecab
아버지 NNG,*,F,아버지,*,*,*,*
가 JKS,*,F,가,*,*,*,*
방 NNG,장소,T,방,*,*,*,*
에 JKB,*,F,에,*,*,*,*
들어가 VV,*,F,들어가,*,*,*,*
신다  EP+EC,*,F,신다,Inflect,EP,EC,시/EP/*+ㄴ다/EC/*
EOS

> git clone https://github.com/i0seph/textsearch_ko.git
> cd textsearch_ko
> make USE_PGXS=1
postgres.h 못찾을 경우
> apt install postgresql-server-dev-18
> make USE_PGXS=1 install

> psql -U paradedb
paradedb=# \i ts_mecab_ko.sql

# 벤치마크 실행
> docker exec -i paradedb psql -U paradedb -d paradedb < benchmark.sql

# 정지
> docker compose down

# 데이터를 포함 삭제
> docker compose down -v
```
