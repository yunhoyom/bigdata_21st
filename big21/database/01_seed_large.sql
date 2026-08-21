-- ============================================================
-- seed_large.sql (v2.0) — 실무형 전자상거래 대용량 실습 데이터
-- ============================================================
-- 작성일: 2026-06-23
-- 검증 환경: PostgreSQL 16.14 (Ubuntu / Docker postgres:16 동일 메이저)
--
-- [이 스크립트가 만드는 것]
--   실제 쇼핑몰의 핵심 테이블 구조(정규화된 5개 테이블)를 그대로 본떠
--   대용량 실습 데이터를 만든다. ch_09(제약조건·인덱스) 단원에서
--   ① 다양한 제약조건(PK/FK/UNIQUE/CHECK/NOT NULL/DEFAULT)이
--      어떻게 데이터 무결성을 지키는지,
--   ② 인덱스 유무에 따라 조회 성능이 어떻게 달라지는지(Seq Scan ↔ Index Scan)
--   를 EXPLAIN ANALYZE 로 "직접 측정"하기 위한 데이터셋이다.
--
-- [데이터 규모]
--   categories       14 행   (상품 분류)
--   customers    50,000 행   (회원)
--   products      1,000 행   (상품)
--   orders      200,000 행   (주문 헤더: "누가 언제 무슨 상태로 주문했나")
--   order_items  ~1,000,000 행 (주문 상세: "그 주문에 어떤 상품을 몇 개")
--
-- ============================================================
-- [실무 핵심 ① 주문은 왜 2개 테이블로 쪼개나? — orders / order_items]
--   초보자용 예제는 흔히 "주문 = 상품 1개"로 단순화하지만,
--   현실의 주문은 한 번에 여러 상품을 담는다(장바구니).
--   그래서 실무에서는 반드시 아래처럼 1:N 으로 나눈다.
--
--     orders (주문 1건)            order_items (그 주문의 품목들)
--     ┌───────────────┐  1      N  ┌──────────────────────┐
--     │ order_id  (PK)│──────────▶ │ order_id   (FK→orders)│
--     │ customer_id   │            │ product_id (FK→products)
--     │ order_date    │            │ quantity              │
--     │ status        │            │ unit_price (주문 시점 가격)
--     │ total_amount  │            └──────────────────────┘
--     └───────────────┘
--
--   ▶ unit_price 를 따로 저장하는 이유: 나중에 상품 가격이 바뀌어도
--     "그 주문 당시 얼마였는지"는 변하면 안 되므로 주문 시점 가격을 박제한다.
--   ▶ total_amount: 조회 성능을 위해 합계를 미리 계산해 저장(비정규화).
--     실무에서 흔한 패턴이라, 이 스크립트도 order_items 합계로 채운다.
-- ============================================================
-- [전체 워크플로우]
--   1) 자식→부모 순서로 기존 테이블 DROP
--   2) 부모→자식 순서로 테이블 CREATE (제약조건 포함)
--   3) 부모→자식 순서로 데이터 INSERT (결정론적 = 누가 돌려도 같은 결과)
--   4) orders.total_amount 를 order_items 합계로 UPDATE (비정규화 갱신)
--   5) ANALYZE 로 통계 갱신 (옵티마이저가 정확한 실행계획을 세우도록)
--   6) 행 수 검증 출력
--
-- [전체 ERD — 화살표는 외래키 참조 방향(자식→부모)]
--
--     categories ◀──── products ◀──── order_items ────▶ orders ────▶ customers
--       (분류)         (상품)        (주문상세)         (주문)        (회원)
--
-- [실행 방법]
--   - psql 직접:   psql -U appuser -d shop -f seed_large_20260623_v2.0.sql
--   - Docker init: 이 파일을 /docker-entrypoint-initdb.d 폴더에 두면
--                  컨테이너 "첫 기동" 시 POSTGRES_DB 대상으로 자동 실행됨.
--
-- [주의] order_items 100만 행 생성에 PC 사양에 따라 수초~수십초 소요.
--        재실행 가능(idempotent): 매번 DROP 후 다시 만든다(학습용 DB에서만 사용).
-- ============================================================

\timing on

-- ─────────────────────────────────────────────
-- 1) 기존 테이블 정리 (자식 → 부모 순서)
--    참조하는 쪽(자식)을 먼저 지워야 FK 제약 위반이 안 난다.
-- ─────────────────────────────────────────────
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS categories;

-- ─────────────────────────────────────────────
-- 2) 스키마 생성 (부모 → 자식 순서)
-- ─────────────────────────────────────────────

-- (2-1) 상품 분류 (가장 작은 마스터 테이블)
CREATE TABLE categories (
    category_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name        varchar(30) NOT NULL UNIQUE          -- 분류명은 중복 불가
);

-- (2-2) 회원
CREATE TABLE customers (
    customer_id integer     GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name        varchar(50) NOT NULL,
    email       varchar(120) NOT NULL UNIQUE,          -- 이메일 중복 가입 차단
    phone       varchar(20),
    birth_date  date,
    gender      char(1)     CHECK (gender IN ('M', 'F')),   -- 값 도메인 제한
    city        varchar(20),
    grade       varchar(10) NOT NULL DEFAULT 'BRONZE'
                CHECK (grade IN ('BRONZE', 'SILVER', 'GOLD', 'VIP')),
    signup_date date        NOT NULL DEFAULT CURRENT_DATE,
    is_active   boolean     NOT NULL DEFAULT true
);

-- (2-3) 상품 (categories 참조)
CREATE TABLE products (
    product_id     integer       GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    category_id    integer       NOT NULL
                   REFERENCES categories(category_id) ON DELETE RESTRICT,
    name           varchar(100)  NOT NULL,
    price          numeric(12,2) NOT NULL CHECK (price > 0),       -- 가격은 양수
    stock_quantity integer       NOT NULL DEFAULT 0
                   CHECK (stock_quantity >= 0),                    -- 재고 음수 금지
    status         varchar(10)   NOT NULL DEFAULT '판매중'
                   CHECK (status IN ('판매중', '품절', '단종')),
    created_at     timestamp     NOT NULL DEFAULT now()
);

-- (2-4) 주문 헤더 (customers 참조)
CREATE TABLE orders (
    order_id      integer       GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id   integer       NOT NULL
                  REFERENCES customers(customer_id) ON DELETE RESTRICT,
    order_date    timestamp     NOT NULL DEFAULT now(),
    status        varchar(10)   NOT NULL DEFAULT '결제완료'
                  CHECK (status IN ('결제완료', '배송중', '배송완료', '취소', '환불')),
    total_amount  numeric(14,2) NOT NULL DEFAULT 0 CHECK (total_amount >= 0),
    shipping_city varchar(20)
);

-- (2-5) 주문 상세 (orders·products 참조) — 가장 큰 테이블
CREATE TABLE order_items (
    order_item_id integer       GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id      integer       NOT NULL
                  REFERENCES orders(order_id) ON DELETE CASCADE,   -- 주문 삭제 시 품목도 함께
    product_id    integer       NOT NULL
                  REFERENCES products(product_id) ON DELETE RESTRICT,
    quantity      integer       NOT NULL CHECK (quantity > 0),
    unit_price    numeric(12,2) NOT NULL CHECK (unit_price >= 0),  -- 주문 시점 가격 스냅샷
    UNIQUE (order_id, product_id)                                   -- 한 주문에 같은 상품 중복 금지
);

-- ─────────────────────────────────────────────
-- 3) 데이터 생성 (결정론적: random 없이 generate_series 일련번호로만 생성)
-- ─────────────────────────────────────────────

-- (3-1) 분류 14종
INSERT INTO categories (name) VALUES
    ('전자제품'), ('컴퓨터'), ('모바일'), ('가전'),
    ('의류'), ('신발'), ('식품'), ('음료'),
    ('도서'), ('가구'), ('주방'), ('스포츠'),
    ('뷰티'), ('완구');

-- (3-2) 회원 5만 명
--   - 이름: 성씨 10종 × 이름조각 배열을 일련번호로 조합 → 한국식 이름처럼 보이게
--   - 이메일: 일련번호 기반이라 절대 중복되지 않음(UNIQUE 충족)
--   - 등급: 60% BRONZE / 25% SILVER / 12% GOLD / 3% VIP (실제 등급 분포 흉내)
--   - 생년월일: 1965~2005년 사이로 분산
--   - 가입일: 2020~2025년 사이로 분산
INSERT INTO customers (name, email, phone, birth_date, gender, city, grade, signup_date, is_active)
SELECT
    (ARRAY['김','이','박','최','정','강','조','윤','장','임'])[1 + (g % 10)]
      || (ARRAY['민','서','지','현','준','수','예','하','도','시'])[1 + ((g / 10) % 10)]
      || (ARRAY['준','우','연','아','은','호','진','영','빈','윤'])[1 + ((g / 100) % 10)]   AS name,
    'user' || g || '@' ||
      (ARRAY['gmail.com','naver.com','daum.net','kakao.com','outlook.com'])[1 + (g % 5)]    AS email,
    '010-' || lpad(((g * 13) % 10000)::text, 4, '0')
            || '-' || lpad(((g * 7)  % 10000)::text, 4, '0')                                AS phone,
    (DATE '1965-01-01' + ((g * 17) % 14600))                                                AS birth_date,  -- ~1965~2004
    (ARRAY['M','F'])[1 + (g % 2)]                                                           AS gender,
    (ARRAY['서울','부산','대구','인천','광주','대전','울산','세종','수원',
           '성남','고양','용인','창원','청주','전주','천안','김해'])[1 + (g % 17)]           AS city,
    CASE
        WHEN (g % 100) < 60 THEN 'BRONZE'
        WHEN (g % 100) < 85 THEN 'SILVER'
        WHEN (g % 100) < 97 THEN 'GOLD'
        ELSE 'VIP'
    END                                                                                     AS grade,
    (DATE '2020-01-01' + ((g * 11) % 2100))                                                 AS signup_date, -- ~2020~2025
    (g % 20 <> 0)                                                                           AS is_active    -- 5%는 비활성
FROM generate_series(1, 50000) AS g;

-- (3-3) 상품 1천 개
--   - category_id: 14개 분류에 고르게 배정
--   - 가격: 5,000원 ~ 약 2,000,000원 사이로 분산(numeric)
--   - 재고: 0~499 (일부 0 → 품절 처리)
--   - 상태: 재고 0이면 품절, 50개당 1개는 단종, 나머지는 판매중
INSERT INTO products (category_id, name, price, stock_quantity, status, created_at)
SELECT
    1 + (g % 14)                                                          AS category_id,
    (ARRAY['프리미엄','베이직','스마트','에코','클래식','모던','컴팩트',
           '울트라','데일리','프로'])[1 + (g % 10)]
      || ' ' ||
    (ARRAY['세트','패키지','에디션','모델','시리즈','버전','타입',
           '플러스','라이트','맥스'])[1 + ((g / 10) % 10)]
      || ' ' || g                                                         AS name,
    ((5 + (g % 400)) * 1000 + (g % 100) * 10)::numeric(12,2)              AS price,          -- 5,000~404,990 분산
    ((g * 37) % 500)                                                      AS stock_quantity,
    CASE
        WHEN ((g * 37) % 500) = 0 THEN '품절'
        WHEN (g % 50) = 0         THEN '단종'
        ELSE '판매중'
    END                                                                   AS status,
    (TIMESTAMP '2022-01-01 00:00:00' + ((g % 1000) || ' days')::interval) AS created_at
FROM generate_series(1, 1000) AS g;

-- (3-4) 주문 헤더 20만 건
--   - customer_id: 5만 회원에 고르게 분포(회원당 평균 4건)
--   - order_date: 2023-01-01 ~ 약 2.5년 범위로 분산(범위 조회 인덱스 실습용)
--   - status: 배송완료 다수 + 배송중/결제완료/취소/환불 소수
--   - total_amount: 일단 0으로 넣고, 아래 4단계에서 order_items 합계로 채움
INSERT INTO orders (customer_id, order_date, status, total_amount, shipping_city)
SELECT
    1 + (g % 50000)                                                       AS customer_id,
    (TIMESTAMP '2023-01-01 00:00:00'
        + ((g % 900) || ' days')::interval
        + ((g % 24)  || ' hours')::interval)                              AS order_date,
    CASE
        WHEN (g % 100) < 70 THEN '배송완료'
        WHEN (g % 100) < 85 THEN '배송중'
        WHEN (g % 100) < 93 THEN '결제완료'
        WHEN (g % 100) < 98 THEN '취소'
        ELSE '환불'
    END                                                                   AS status,
    0                                                                     AS total_amount,
    (ARRAY['서울','부산','대구','인천','광주','대전','울산','세종','수원',
           '성남','고양','용인','창원','청주','전주','천안','김해'])[1 + (g % 17)] AS shipping_city
FROM generate_series(1, 200000) AS g;

-- (3-5) 주문 상세 ~100만 행
--   각 주문(order_id)마다 1~9개의 품목을 단다(order_id % 9 로 결정 → 평균 5개).
--   같은 주문 안에서는 product_id 가 연속이라 서로 겹치지 않음 → UNIQUE(order_id,product_id) 충족.
--   unit_price 는 그 상품의 현재 가격을 "주문 시점 가격"으로 박제.
INSERT INTO order_items (order_id, product_id, quantity, unit_price)
SELECT
    o.order_id,
    p.product_id,
    1 + ((o.order_id + li.n) % 5)                                         AS quantity,   -- 1~5개
    p.price                                                               AS unit_price  -- 가격 스냅샷
FROM orders o
CROSS JOIN LATERAL generate_series(1, 1 + (o.order_id % 9)) AS li(n)
JOIN products p
  ON p.product_id = 1 + ((o.order_id * 7 + li.n) % 1000);

-- ─────────────────────────────────────────────
-- 4) orders.total_amount 를 order_items 합계로 갱신 (비정규화 — 실무 패턴)
-- ─────────────────────────────────────────────
UPDATE orders o
SET total_amount = s.total
FROM (
    SELECT order_id, SUM(quantity * unit_price) AS total
    FROM order_items
    GROUP BY order_id
) s
WHERE o.order_id = s.order_id;

-- ─────────────────────────────────────────────
-- 5) 통계 갱신 (옵티마이저가 정확한 실행계획을 세우도록)
-- ─────────────────────────────────────────────
ANALYZE categories;
ANALYZE customers;
ANALYZE products;
ANALYZE orders;
ANALYZE order_items;

-- ─────────────────────────────────────────────
-- 6) 생성 결과 검증
-- ─────────────────────────────────────────────
SELECT 'categories'  AS table_name, count(*) AS rows FROM categories
UNION ALL SELECT 'customers',  count(*) FROM customers
UNION ALL SELECT 'products',   count(*) FROM products
UNION ALL SELECT 'orders',     count(*) FROM orders
UNION ALL SELECT 'order_items',count(*) FROM order_items
ORDER BY rows;

-- ============================================================
-- [다음 단계 — ch_09 인덱스 실습 가이드]
--   아래 컬럼들은 외래키지만 PostgreSQL이 "자동으로 인덱스를 만들지 않는다".
--   따라서 인덱스 효과를 실측하기에 가장 좋은 대상이다.
--     · orders.customer_id        (특정 회원의 주문 찾기)
--     · order_items.order_id       (특정 주문의 품목 찾기)
--     · order_items.product_id     (특정 상품이 팔린 내역 찾기)
--
--   ▶ 실습 1) 인덱스 없이 — Seq Scan 확인
--     EXPLAIN ANALYZE
--     SELECT * FROM order_items WHERE product_id = 500;
--
--   ▶ 실습 2) 인덱스 생성
--     CREATE INDEX idx_order_items_product_id ON order_items (product_id);
--
--   ▶ 실습 3) 같은 질의 재측정 — Index Scan 으로 바뀌고 시간이 급감하는지 비교
--     EXPLAIN ANALYZE
--     SELECT * FROM order_items WHERE product_id = 500;
--
--   ▶ 심화) 범위 조회 인덱스
--     CREATE INDEX idx_orders_order_date ON orders (order_date);
--     EXPLAIN ANALYZE
--     SELECT count(*) FROM orders
--     WHERE order_date >= '2024-01-01' AND order_date < '2024-02-01';
-- ============================================================