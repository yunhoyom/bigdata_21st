-- ============================================================
-- seed_realistic_20260628_v3.0.sql — 실무형 전자상거래 실습 데이터 (현실화 버전)
-- ============================================================
-- 작성일: 2026-06-28
-- 검증 환경: PostgreSQL 16.14 (실제 적재·검증 완료)
-- 스키마: seed_large_v2.0 과 100% 동일 (기존 50문제 문제집/해설서 그대로 사용 가능)
--
-- ────────────────────────────────────────────────────────────
-- [왜 이 버전을 만들었나 — 기존 seed의 한계]
--   기존 seed_large(v2.0)는 "난수 없이 일련번호 g 규칙"으로만 데이터를 만들어
--   재현성은 완벽했지만, 마케팅 지표가 비현실적으로 나오는 부작용이 있었다.
--
--     ① 모든 회원이 정확히 4건씩 주문   → 재구매율 100%, 빈도 분포 단일
--     ② 회원 등급과 주문 상태가 같은 수열(g % 100)에서 파생되어 "연동"
--        → VIP 1,500명의 주문이 전부 취소·환불 → VIP 유효매출 0원
--
--   현업에서 "재구매율 100%", "최우수 등급 매출 0원"은 인사이트가 아니라
--   데이터 파이프라인 경고 신호다. 교육용으로 그 점을 가르치기엔 좋지만,
--   "정상적인 분석 결과"를 체험하기엔 부적합하다.
--
-- [이 버전이 고치는 방법 — 4가지 핵심 설계]
--   (1) 재현성은 유지하되 모듈러 상관을 제거: 맨 위에서 setseed() 한 번 고정 후
--       이후 모든 무작위는 random() 사용 → "같은 스크립트를 처음부터 끝까지
--       한 세션에서 실행하면" 누가 돌려도 동일 결과. (g % 100 식 상관관계 소멸)
--   (2) 회원별 주문수를 '분포'로 가변 생성:
--       1건(35%) ~ 헤비바이어 10~20건(3%) → 재구매율·빈도 세분화가 현실적으로.
--   (3) 주문 상태를 '등급과 무관하게' 결정(취소·환불 ~7%, 최근 주문일수록 배송중/결제완료)
--       → 어느 등급이든 유효주문을 정상적으로 가진다.
--   (4) ★등급을 '주문을 다 만든 뒤' 실제 유효 구매액 백분위로 부여★
--       → VIP = 상위 3% 소비자. 즉 "등급이 행동(구매액)을 올바르게 반영".
--          이것이 'VIP 매출 0' 문제를 근본적으로 없애고 등급을 '적합'하게 만든다.
--   (보너스) 상품 선택에 인기 편중(power(random(),2)) → 베스트셀러·ABC 파레토 자연 발생.
--            is_active 도 최근 구매 여부로 결정(휴면 = 오래 안 산 사람).
--
-- ────────────────────────────────────────────────────────────
-- [전체 ERD — 화살표는 외래키 참조 방향(자식 → 부모)]
--   categories ◀── products ◀── order_items ──▶ orders ──▶ customers
--     (분류)       (상품)       (주문상세)        (주문)       (회원)
--
-- [전체 워크플로우]
--   0) setseed 로 난수 시드 고정(재현성)
--   1) 자식→부모 순서로 DROP, 부모→자식 순서로 CREATE (스키마는 기존과 동일)
--   2) categories(14) → customers(5만, 등급은 일단 BRONZE) → products(1천, 인기/가격 분산)
--   3) orders: 회원별 '가변' 주문수로 생성, 상태는 등급과 무관(취소·환불 ~7%)
--   4) order_items: 인기 편중으로 상품 선택(ON CONFLICT 로 한 주문 내 중복 자동 제거)
--   5) orders.total_amount = order_items 합계 (비정규화 갱신)
--   6) ★customers.grade = 유효 구매액 백분위로 재부여 (VIP=상위 3%)★
--   7) customers.is_active = 최근 1년 내 구매 여부로 재설정
--   8) ANALYZE → 행 수 및 핵심 지표 검증 출력
--
-- [실행 방법]
--   psql -U appuser -d shop -f seed_realistic_20260628_v3.0.sql
--   ※ 반드시 '파일 전체를 한 번에' 실행할 것(재현성은 단일 세션 순차 실행 전제).
-- ============================================================

\timing on

-- ─────────────────────────────────────────────
-- 0) 난수 시드 고정 — 재현성의 핵심
--    setseed 이후의 random() 들은 호출 순서가 같으면 항상 같은 값을 낸다.
-- ─────────────────────────────────────────────
SELECT setseed(0.20260628);

-- ─────────────────────────────────────────────
-- 1) 기존 테이블 정리 (자식 → 부모)
-- ─────────────────────────────────────────────
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS categories;

-- ─────────────────────────────────────────────
-- 2) 스키마 생성 (부모 → 자식) — seed_large_v2.0 과 동일
-- ─────────────────────────────────────────────
CREATE TABLE categories (
    category_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name        varchar(30) NOT NULL UNIQUE
);

CREATE TABLE customers (
    customer_id integer     GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name        varchar(50) NOT NULL,
    email       varchar(120) NOT NULL UNIQUE,
    phone       varchar(20),
    birth_date  date,
    gender      char(1)     CHECK (gender IN ('M', 'F')),
    city        varchar(20),
    grade       varchar(10) NOT NULL DEFAULT 'BRONZE'
                CHECK (grade IN ('BRONZE', 'SILVER', 'GOLD', 'VIP')),
    signup_date date        NOT NULL DEFAULT CURRENT_DATE,
    is_active   boolean     NOT NULL DEFAULT true
);

CREATE TABLE products (
    product_id     integer       GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    category_id    integer       NOT NULL
                   REFERENCES categories(category_id) ON DELETE RESTRICT,
    name           varchar(100)  NOT NULL,
    price          numeric(12,2) NOT NULL CHECK (price > 0),
    stock_quantity integer       NOT NULL DEFAULT 0 CHECK (stock_quantity >= 0),
    status         varchar(10)   NOT NULL DEFAULT '판매중'
                   CHECK (status IN ('판매중', '품절', '단종')),
    created_at     timestamp     NOT NULL DEFAULT now()
);

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

CREATE TABLE order_items (
    order_item_id integer       GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id      integer       NOT NULL
                  REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id    integer       NOT NULL
                  REFERENCES products(product_id) ON DELETE RESTRICT,
    quantity      integer       NOT NULL CHECK (quantity > 0),
    unit_price    numeric(12,2) NOT NULL CHECK (unit_price >= 0),
    UNIQUE (order_id, product_id)
);

-- ─────────────────────────────────────────────
-- 3-1) 분류 14종
-- ─────────────────────────────────────────────
INSERT INTO categories (name) VALUES
    ('전자제품'), ('컴퓨터'), ('모바일'), ('가전'),
    ('의류'), ('신발'), ('식품'), ('음료'),
    ('도서'), ('가구'), ('주방'), ('스포츠'),
    ('뷰티'), ('완구');

-- ─────────────────────────────────────────────
-- 3-2) 회원 5만 명
--   - 등급은 '일단 BRONZE' 로 둔다(6단계에서 실제 구매액 기준으로 재부여).
--   - 이메일은 g 기반이라 UNIQUE 충족. 그 외 속성은 random() 으로 현실 분산.
--   - birth_date: 1960~2006, signup_date: 2019-01 ~ 2026-06
-- ─────────────────────────────────────────────
INSERT INTO customers (name, email, phone, birth_date, gender, city, grade, signup_date, is_active)
SELECT
    (ARRAY['김','이','박','최','정','강','조','윤','장','임'])[1 + floor(random()*10)::int]
      || (ARRAY['민','서','지','현','준','수','예','하','도','시'])[1 + floor(random()*10)::int]
      || (ARRAY['준','우','연','아','은','호','진','영','빈','윤'])[1 + floor(random()*10)::int]   AS name,
    'user' || g || '@' ||
      (ARRAY['gmail.com','naver.com','daum.net','kakao.com','outlook.com'])[1 + floor(random()*5)::int] AS email,
    '010-' || lpad(floor(random()*10000)::int::text, 4, '0')
            || '-' || lpad(floor(random()*10000)::int::text, 4, '0')                              AS phone,
    (DATE '1960-01-01' + floor(random()*16800)::int)                                              AS birth_date,  -- ~1960~2006
    (ARRAY['M','F'])[1 + floor(random()*2)::int]                                                  AS gender,
    (ARRAY['서울','부산','대구','인천','광주','대전','울산','세종','수원',
           '성남','고양','용인','창원','청주','전주','천안','김해'])[1 + floor(random()*17)::int]  AS city,
    'BRONZE'                                                                                       AS grade,       -- 6단계에서 재부여
    (DATE '2019-01-01' + floor(random()*2735)::int)                                               AS signup_date, -- 2019~2026-06
    true                                                                                          AS is_active    -- 7단계에서 재설정
FROM generate_series(1, 50000) AS g;

-- ─────────────────────────────────────────────
-- 3-3) 상품 1천 개
--   - 가격 5,000~404,990 분산, 재고 0~499
--   - 품절(약 1%)은 재고 0으로 일치, 단종 약 3%, 나머지 판매중
-- ─────────────────────────────────────────────
-- ★products 도 동일한 버그 회피: 모든 random() 을 내부 서브쿼리(base)의 SELECT 목록에서
--   인라인 호출 → 상품마다 재고/상태가 달라진다. (품절이면 재고 0으로 일치)
INSERT INTO products (category_id, name, price, stock_quantity, status, created_at)
SELECT
    base.category_id,
    base.name,
    base.price,
    CASE WHEN base.rstat < 0.01 THEN 0 ELSE base.stock_base END           AS stock_quantity,
    CASE WHEN base.rstat < 0.01 THEN '품절'
         WHEN base.rstat < 0.04 THEN '단종'
         ELSE '판매중' END                                                AS status,
    base.created_at
FROM (
    SELECT
        1 + floor(random()*14)::int                                       AS category_id,
        (ARRAY['프리미엄','베이직','스마트','에코','클래식','모던','컴팩트',
               '울트라','데일리','프로'])[1 + floor(random()*10)::int]
          || ' ' ||
        (ARRAY['세트','패키지','에디션','모델','시리즈','버전','타입',
               '플러스','라이트','맥스'])[1 + floor(random()*10)::int]
          || ' ' || g                                                     AS name,
        ((5 + floor(random()*400)) * 1000 + floor(random()*100)*10)::numeric(12,2) AS price,
        1 + floor(random()*499)::int                                      AS stock_base,
        random()                                                          AS rstat,
        (TIMESTAMP '2022-01-01 00:00:00' + (floor(random()*1000)::int || ' days')::interval) AS created_at
    FROM generate_series(1, 1000) AS g
) AS base;

-- ─────────────────────────────────────────────
-- 3-4) 주문 — 회원별 '가변' 주문수 (현실적 분포)
--   주문수 분포: 1건 35% / 2건 25% / 3건 18% / 4~5건 12% / 6~9건 7% / 10~20건 3%
--     → 평균 ≈ 2.9건, 재구매율(2건 이상) ≈ 65% (현실적)
--   상태: 등급과 무관! 취소 5% + 환불 2%, 최근 14일 내 주문은 결제완료/배송중,
--         45일 내는 배송중, 그 외는 배송완료 (현실적 배송 라이프사이클)
--   order_date: 2023-01-01 ~ 2026-06-28(오늘) 사이 무작위 분산 → 최근성(Recency) 의미 있음
-- ─────────────────────────────────────────────
-- ★중요(버그 회피): random() 은 반드시 '행을 만드는 서브쿼리의 SELECT 목록'에서
--   인라인으로 호출해야 행마다 새 값이 나온다. 비상관 LATERAL (SELECT random())
--   패턴은 쿼리당 1회만 평가되어 모든 행이 같은 값이 되므로 쓰면 안 된다.
INSERT INTO orders (customer_id, order_date, status, total_amount, shipping_city)
SELECT
    base.customer_id,
    base.order_date,
    CASE
        WHEN base.st < 0.05 THEN '취소'
        WHEN base.st < 0.07 THEN '환불'
        WHEN base.order_date > TIMESTAMP '2026-06-28' - INTERVAL '14 days'
             THEN CASE WHEN base.st2 < 0.5 THEN '결제완료' ELSE '배송중' END
        WHEN base.order_date > TIMESTAMP '2026-06-28' - INTERVAL '45 days'
             THEN '배송중'
        ELSE '배송완료'
    END                                                                  AS status,
    0                                                                    AS total_amount,
    base.shipping_city
FROM (
    SELECT
        c.customer_id,
        (TIMESTAMP '2023-01-01 00:00:00'
            + (random() * (DATE '2026-06-28' - DATE '2023-01-01')) * INTERVAL '1 day'
            + (random()*24) * INTERVAL '1 hour')                          AS order_date,
        random()                                                          AS st,   -- 취소·환불 판정
        random()                                                          AS st2,  -- 결제완료/배송중 분기
        (ARRAY['서울','부산','대구','인천','광주','대전','울산','세종','수원',
               '성남','고양','용인','창원','청주','전주','천안','김해'])[1 + floor(random()*17)::int] AS shipping_city
    FROM (
        SELECT g AS customer_id,
               CASE
                   WHEN z.r < 0.35 THEN 1
                   WHEN z.r < 0.60 THEN 2
                   WHEN z.r < 0.78 THEN 3
                   WHEN z.r < 0.90 THEN 4 + floor(random()*2)::int      -- 4~5
                   WHEN z.r < 0.97 THEN 6 + floor(random()*4)::int      -- 6~9
                   ELSE                10 + floor(random()*11)::int      -- 10~20 (헤비바이어)
               END AS order_count
        FROM (SELECT g, random() AS r FROM generate_series(1, 50000) AS g) AS z
    ) AS c
    CROSS JOIN LATERAL generate_series(1, c.order_count) AS n   -- 회원당 order_count 개의 행 생성
) AS base;

-- ─────────────────────────────────────────────
-- 3-5) 주문 상세 — 인기 편중 상품 선택
--   - 한 주문당 품목 수: 1 ~ 약 10개 (소량 편중)
--   - 상품 선택: power(random(),2) 로 낮은 product_id(=인기상품)에 편중
--                → 베스트셀러/ABC 파레토가 자연스럽게 형성
--   - UNIQUE(order_id,product_id) 충돌 시 ON CONFLICT DO NOTHING 으로
--     한 주문 내 같은 상품 중복을 자동 제거(현실의 장바구니 = 상품별 1줄)
--   - unit_price = 그 상품의 현재가(주문 시점 가격 스냅샷)
-- ─────────────────────────────────────────────
-- ★주문당 품목 수도 '주문별 서브쿼리(oc)의 SELECT 목록'에서 인라인 계산해야
--   주문마다 다른 값이 된다(위 orders 와 동일한 이유).
INSERT INTO order_items (order_id, product_id, quantity, unit_price)
SELECT pk.order_id, pk.product_id, pk.quantity, p.price
FROM (
    SELECT oc.order_id,
           1 + floor(power(random(), 2.0) * 1000)::int AS product_id,   -- 1~1000, 인기 편중
           1 + floor(power(random(), 2.0) * 5)::int    AS quantity      -- 1~5, 소량 편중
    FROM (
        SELECT order_id,
               1 + floor(power(random(), 1.4) * 9)::int AS item_count   -- 주문당 1~10개(소량 편중)
        FROM orders
    ) AS oc
    CROSS JOIN LATERAL generate_series(1, oc.item_count) AS li(n)
) AS pk
JOIN products p ON p.product_id = pk.product_id
ON CONFLICT (order_id, product_id) DO NOTHING;

-- ─────────────────────────────────────────────
-- 4) orders.total_amount = order_items 합계 (비정규화 갱신)
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
-- 6) ★등급 재부여 — 실제 '유효 구매액' 백분위 기준★
--    cume_dist(): 매출 오름차순 누적 분포. 상위 3% → VIP, 다음 12% → GOLD,
--    다음 25% → SILVER, 하위 60% → BRONZE.
--    ⇒ 등급이 구매 행동을 올바르게 반영 → "VIP 매출 0" 문제 원천 제거.
--    (취소·환불만 있거나 주문이 적은 회원은 자연히 BRONZE 로 수렴)
-- ─────────────────────────────────────────────
WITH spend AS (
    SELECT c.customer_id,
           COALESCE(SUM(o.total_amount) FILTER (WHERE o.status NOT IN ('취소','환불')), 0) AS valid_spend
    FROM customers c
    LEFT JOIN orders o ON o.customer_id = c.customer_id
    GROUP BY c.customer_id
),
ranked AS (
    SELECT customer_id, cume_dist() OVER (ORDER BY valid_spend) AS cd
    FROM spend
)
UPDATE customers cu
SET grade = CASE
        WHEN r.cd > 0.97 THEN 'VIP'
        WHEN r.cd > 0.85 THEN 'GOLD'
        WHEN r.cd > 0.60 THEN 'SILVER'
        ELSE 'BRONZE'
    END
FROM ranked r
WHERE r.customer_id = cu.customer_id;

-- ─────────────────────────────────────────────
-- 7) is_active 재설정 — 최근성 기반
--    최근 1년(365일) 내 유효 주문이 있으면 활성, 없으면 휴면(30%만 활성 유지),
--    유효 주문이 아예 없으면 비활성.
-- ─────────────────────────────────────────────
WITH last_order AS (
    SELECT c.customer_id,
           MAX(o.order_date) FILTER (WHERE o.status NOT IN ('취소','환불')) AS last_dt
    FROM customers c
    LEFT JOIN orders o ON o.customer_id = c.customer_id
    GROUP BY c.customer_id
)
UPDATE customers cu
SET is_active = CASE
        WHEN l.last_dt IS NULL THEN false
        WHEN l.last_dt > TIMESTAMP '2026-06-28' - INTERVAL '365 days' THEN true
        ELSE (random() < 0.30)
    END
FROM last_order l
WHERE l.customer_id = cu.customer_id;

-- ─────────────────────────────────────────────
-- 8) 통계 갱신
-- ─────────────────────────────────────────────
ANALYZE categories;
ANALYZE customers;
ANALYZE products;
ANALYZE orders;
ANALYZE order_items;

-- ─────────────────────────────────────────────
-- 9) 검증 출력 — 행 수 + 등급이 '적합'해졌는지 핵심 지표
-- ─────────────────────────────────────────────
-- (9-1) 행 수
SELECT 'categories'  AS table_name, count(*) AS rows FROM categories
UNION ALL SELECT 'customers',  count(*) FROM customers
UNION ALL SELECT 'products',   count(*) FROM products
UNION ALL SELECT 'orders',     count(*) FROM orders
UNION ALL SELECT 'order_items',count(*) FROM order_items
ORDER BY rows;

-- (9-2) ★핵심 검증: 등급별 유효매출 — 이제 VIP 가 가장 높아야 정상★
SELECT cu.grade AS 등급,
       count(DISTINCT cu.customer_id) AS 회원수,
       count(o.*) FILTER (WHERE o.status NOT IN ('취소','환불')) AS 유효주문,
       COALESCE(SUM(o.total_amount) FILTER (WHERE o.status NOT IN ('취소','환불')),0) AS 유효매출,
       ROUND(AVG(o.total_amount) FILTER (WHERE o.status NOT IN ('취소','환불')),0) AS 평균객단가
FROM customers cu
LEFT JOIN orders o ON o.customer_id = cu.customer_id
GROUP BY cu.grade
ORDER BY 유효매출 DESC;

-- ============================================================
-- [참고] 기존 문제집/해설서(v2.0)의 '실행 결과 수치'는 옛 seed 기준이므로
--        이 seed 로 바꾸면 숫자는 달라진다(SQL 기법·정답 구조는 동일하게 통용).
--        ch_09 인덱스 실습(외래키 인덱스 유무 비교)도 그대로 사용 가능.
-- ============================================================
