-- ============================================================
-- seed_large.sql — 대용량 실습 데이터 생성 스크립트
-- ============================================================
-- 목적:
--   ch_09(제약조건과 인덱스) 인덱스 단원에서, 인덱스 유무에 따른
--   조회 성능 차이를 EXPLAIN ANALYZE 로 실제 측정하기 위한
--   대용량 데이터셋을 만든다.
--     members  5만 행 / products 1천 행 / orders 100만 행
--
-- 사용법 (Windows 11 PowerShell, shop_lab DB 접속 가능한 상태):
--   psql -d shop_lab -f data/seed_large.sql
--
-- 특징:
--   - 재실행 가능: 기존 테이블을 DROP 후 다시 만든다.
--   - 결정론적 생성: 난수(random) 없이 generate_series 의 일련번호로만
--     값을 만들어, 누가 언제 실행해도 같은 데이터가 나온다(재현 가능).
--
-- 주의:
--   - orders 100만 행 생성에 일반 PC 기준 수초~수십초가 걸릴 수 있다.
--   - 이 스크립트는 ch_09 기준 세 테이블(members·products·orders)을
--     덮어쓴다. 기존 실습 데이터가 있으면 사라지므로 학습용 DB에서 쓴다.
-- ============================================================

\timing on

-- 1) 기존 테이블 정리 (참조 순서상 orders 를 먼저 지운다)
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS members;

-- 2) 스키마 생성 (ch_09 기준 세 테이블)
CREATE TABLE members (
    id    integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name  varchar(50)  NOT NULL,
    email varchar(100) NOT NULL,
    age   integer
);

CREATE TABLE products (
    id    integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name  varchar(100)   NOT NULL,
    price numeric(10, 2) NOT NULL
);

CREATE TABLE orders (
    id         integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    member_id  integer NOT NULL,
    product_id integer NOT NULL,
    quantity   integer NOT NULL
);

-- 3) 대용량 데이터 생성 (generate_series, 결정론적)

-- 회원 5만 명: member1@example.com ~ member50000@example.com
INSERT INTO members (name, email, age)
SELECT '회원' || g,
       'member' || g || '@example.com',
       20 + (g % 50)                       -- 나이 20~69 순환
FROM generate_series(1, 50000) AS g;

-- 상품 1천 개: 가격 1,000 ~ 100,500 순환
INSERT INTO products (name, price)
SELECT '상품' || g,
       (1000 + (g % 200) * 500)::numeric(10, 2)
FROM generate_series(1, 1000) AS g;

-- 주문 100만 건: member_id 1~5만, product_id 1~1천에 고르게 분포
INSERT INTO orders (member_id, product_id, quantity)
SELECT 1 + (g % 50000),                    -- 회원 1~50000 순환
       1 + (g % 1000),                     -- 상품 1~1000 순환
       1 + (g % 5)                         -- 수량 1~5 순환
FROM generate_series(1, 1000000) AS g;

-- 4) 통계 갱신 (플래너가 정확한 실행 계획을 세우도록)
ANALYZE members;
ANALYZE products;
ANALYZE orders;

-- 5) 생성 결과 확인
SELECT 'members'  AS table_name, count(*) AS rows FROM members
UNION ALL
SELECT 'products', count(*) FROM products
UNION ALL
SELECT 'orders',   count(*) FROM orders;

-- 다음 단계(본문 참고): 인덱스 없이 EXPLAIN ANALYZE 로 Seq Scan 을 확인한 뒤
--   CREATE INDEX idx_orders_member_id ON orders (member_id);
-- 를 만들고 같은 질의를 다시 측정해 Index Scan 으로 바뀌는지 비교한다.
