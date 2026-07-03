select count(*) from customers;
select count(*) from categories;
select count(*) from order_items;
select count(*) from orders;
select count(*) from products;



-- 정렬
-- 문제 : 상품 가격이 비싼 순서로 정렬
select 
	   p."name" 
	 , p.price 
  from products p
 order by p.price desc
 limit 10
;

-- 문제 : 상품 카테고리별 가격이 비싼 순으로 조회
select p.category_id, p.price
  from products p 
 order by p.category_id asc, p.price desc
;


-- null 확인 : category_id 값이 null일 수가 없다.
-- FK(외래키) 때문
select count(p.category_id)		-- 3. row의 개수
  from products p				-- 1. 메모리에 products 테이블 로딩 -> 1000개 row 
 where p.category_id is null	-- 2. 0개 row 추출 
-- order by p.category_id asc nulls first
;


-- 문제 : 가격이 비싼 상위 3개
select p."name" 
     , p.price 
  from products p 
 order by p.price desc
 limit 3
--offset 1
;

-- 문제 : 상품을 1페이지에 10개씩 조회
-- 현재 1페이지
select p."name"
	 , p.price 
  from products p 
 order by p.price asc
 limit 10 offset 2 * 10
--  limit 10 offset x * 10  x+1 페이지가 됨.
;

-- 필요한 고객 정보(고객아이디, 이름, 도시, 등급) 컬럼만 추출
select c.customer_id
	 , c."name"
	 , c.city 
	 , c.grade
  from customers c 
 limit 5
;

select distinct c.city 	-- 17개 도시
  from customers c 		-- 고객 : 50,000명
;

-- 등급이 어떤 값을 가지고 있는지 확인
select distinct c.grade 
  from customers c 
;
-- 조건에 맞는 고객 추출
-- 서울에 살고, vip인 고객 아이디, 이름, 도시, 등급 조회해서 상품 정보를 문자로 전송
select 
	   c.customer_id
	 , c."name" 
	 , c.phone 
  from customers c 
 where c.city = '서울'
   and c.grade = 'VIP'
-- limit 5
;

-- 서울에 살고, vip인 고객 수 조회
select 
	   count(*)
  from customers c 
 where c.city = '서울'
   and c.grade = 'VIP'
-- limit 5
;

-- 고객 등급 추출 : 등급에 어떤 값이 있는지 추출
select distinct c.grade
  from customers c 
 order by c.grade asc	-- 알파벳 정렬
;

-- 고객 등급 추출 : 등급이 몇 단계가 있는지 추출
select count(distinct c.grade)
  from customers c 
-- order by c.grade asc	-- 알파벳 정렬
;

-- 고객 등급이 'GOLD', 'VIP'이고 부산에 살고 생일이 1990~1999년생 조회
select c."name" 
	 , c.grade 
	 , c.city
  from customers c 
 where c.grade in ('VIP', 'GOLD')
   and c.city = '부산' -- date '1990-01-01' 문자열을 date 타입으로 변환
   and c.birth_date between date '19900101' and date '19991231'
   

-- 상품명, 가격, 부가세 포함 가격 조회
-- 상위 5개 조회
select p."name" 		-- 2. 한 개 row씩 추출, 컬럼 선택해서 새로운 row 생성, 1000  row
	 , p.price 
	 , p.price * 1.1 as vat_price
  from products p 		-- 1. 1000 row 메모리 적재, 현재 where 없음. 전체 행 선택
 order by p.price desc	-- 3. select 후에 실행. name, price, price*1.1
 limit 5
;

/*
 * 2. 집계와 그룹화
 *   여러 행을 하나로 압축(집계)하고, 같은 값끼리 묶어(group) 계산
 */
-- 집계 함수 : count, min, max, sum, avg

-- 전체 고객 데이터에서 고객 수, 최고령 고객 생일, 최연소 고객 생일 조회
-- 전체 고객 데이터에서 : "특정 조건이 없다"를 의미. where 필요x

select count(*) as customer_count
	 , min(c.birth_date) as oldest
	 , max(c.birth_date) as youngest 
  from customers c
;  
-- vip 고객 데이터에서 고객 수, 최고령 고객 생일, 최연소 고객 생일 조회

select count(*) as customer_count
	 , min(c.birth_date) as oldest
	 , max(c.birth_date) as youngest 
  from customers c
 where c.grade = 'VIP'
;

-- select count(*) : * All column
-- count(특정 컬럼명) : 해당 컬럼의 row 수, 컬럼에 null 있으면 null은 제외되고 개수 파악.

-- 2.2 group by : 특정 컬럼의 특정 값으로 그룹으로 묶는다. 
-- grade 컬럼 group => 4개 그룹
-- 문법 : group by 컬럼명1, 컬럼명2, ...

-- 고객 등급별 인원 수와 비율 조회

select c.grade
	 , count(*) as cnt
	 , round(100 * count(*) / sum(count(*)) over(),1) as grade_pct
  from customers c 
 group by c.grade 
 order by cnt desc
;

-- 도시별 고객 수를 파악해서 도시, 고객수 조회
-- 상위 5개 도시 조회
select c.city
	 , count(*) as cnt
  from customers c 
 group by c.city 
 order by cnt desc 
 limit 5
 
-- 조건에 맞는 그룹 조회 : 그룹 필터 =>  group by -> having 조건
-- 카테고리별 상품 수와 평균 가격 조회.
-- 평균 가격 > 186000 조회
 
select count(distinct p.category_id) from products p; 
select * from categories c;
 
select p.category_id						-- 4번 실행
	 , count(*) as cnt
	 , round(avg(p.price),0) as price_avg
  from products p 							-- 1번 실행
 group by p.category_id			-- 카테고리별	-- 2번 실행
having avg(p.price ) >= 186000				-- 3번 실행
 order by price_avg desc
;

-- 2.4 case: 구간 분리
-- 가격이 50000원보다 적으면 '저가', 50000 <= 가격 < 200000 '중가'
-- 200000 <= 가격 : '고가'
-- 저가 상품 수, 중가 상품 수, 고가 상품 수 : 가격대별 상품 수
select case when p.price < 50000 then '저가'
	        when p.price < 200000 then '중가'
	        else '고가'
	   end as 가격대
	 , count(*) as cnt
  from products p 
 group by 1			-- select 1번째 column 가져와라.(select 실행x.코드를 가져와서 실행함.)
 
-- 2.5 날짜 함수 : 월별 집계
-- 월별 주문 수 조회 -> 5개만 조회
select date_trunc('month', o.order_date)::date as month
	 , count(*) as cnt
  from orders o 
 group by date_trunc('month', o.order_date)::date	-- 월별 grouping
 order by date_trunc('month', o.order_date)::date
 limit 5
;

-- 2.5 날짜 함수 : 월별 집계
-- 월별 주문 수 조회 -> 5개만 조회
select date_trunc('month', o.order_date)::date as month
	 , count(*) as cnt
  from orders o 
 group by 1	-- group by 1 사용 못 하는 DB : oracle
 order by 1 -- order by 1 모든 DB에서 가능
 limit 5
;

select o.order_date
	 , date_trunc('month', o.order_date)::date as mon1	-- ::date : date 타입으로 형 변환
	 , date_trunc('month', o.order_date) as mon2	-- date_trunc는 반환값 타입이 timestamp
  from orders o
 limit 1