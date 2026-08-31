-- 다중 group by + filter 집계
-- 문제 : 카테고리별 상품 수, 판매 중인 상품 수, 단종된 상품 수 구하기

-- 전체 상품 수
select count(*)
  from products p
  
-- 카테고리별 상품 수
select p.category_id 
	 , count(*)
  from products p 
 group by p.category_id
 order by p.category_id
 
-- 판매 중인 상품 수
 select distinct p.status
   from products p 
   
select p.category_id
	 , count(*) as product_count_per_category
	 , count(*) filter (where p.status = '판매중') as number_of_products_per_category
	 , count(*) filter (where p.status = '단종') as number_of_discontinued_products_per_category
  from products p 
 group by p.category_id
 order by p.category_id
;



/*
 * 정규화 : 특정 데이터들을 여러 개 테이블로 나눈 것.
 * JOIN : 테이블 여러 개를 연결
 * 테이블 결합 : join => inner join, outer join
 * inner join : 조건에 일치하는 row 추출 
 * outer join : inner join 결과 + inner 밖의 데이터 추출
 * 
 * 카테시안 곱 join (2 * 2 = 4) 
 */

-- 요건
-- 상품번호, 상품명, 카테고리명, 가격 조회
select p.product_id 
	 , p.name as product_name
	 , c.name as category_name
	 , p.price
  from products p 
  join categories c 
    on p.category_id = c.category_id 
;

select count(*)					-- products : 1000 * categories: 14
  from products p, categories c -- join -> 14000 rows
;

select count(*)
  from products p, categories c
 where p.category_id = c.category_id	-- 1000 row 
;

select p.product_id
	 , p."name" as product_name
	 , c."name" as category_name
	 , p.price 
  from products p, categories c
 where p.category_id = c.category_id	-- 1000 row 
;

-- html 예제 15
-- 요건 : 상품명, 카테고리명, 가격 조회
-- 상품명, 가격 : products table 존재
-- 카테고리명 : categories table 존재
select p."name" as product_name
	 , c."name" as category_name
	 , p.price 
  from products p 
  join categories c 
    on p.category_id = c.category_id 
 limit 5
;

-- html 예제 16
-- 요건 : 주문번호, 회원명, 상품명, 수량, 단가 조회
select o.order_id
	 , c."name" as customer_name
	 , p."name" as product_name
	 , oi.quantity 
	 , oi.unit_price 
  from orders o 
  join customers c on o.customer_id = c.customer_id -- 해당 주문 번호의 회원명 추출
  join order_items oi on o.order_id = oi.order_id 	-- 해당 주문 번호의 수량, 단가 추출
  join products p on oi.product_id = p.product_id	-- 해당 주문 번호의 상품명
 where o.order_id = 12345
 
-- 예제 17
-- 요건 : 카테고리별 주문 수, 매출(sum(수량 * 단가)) 조회
 
select c."name"
--	 , count(distinct oi.order_id) as 주문수
	 , count(*) as 주문수
	 , sum(oi.quantity * oi.unit_price ) as 매출
  from order_items oi
  join products p on oi.product_id = p.product_id 
  join categories c on p.category_id = c.category_id
 group by c."name" 
 
-- 예제 18
-- category_id, category_name, 카테고리별 단종 수 조회
select c.category_id
	 , c."name"  
	 , count(p.product_id ) as 단종수
  from categories c
  left join products p on c.category_id = p.category_id
   and p.status = '단종'
-- where p.status = '단종'
 group by c.category_id 
 order by c.category_id
 
-- 예제 19
-- 서브 쿼리(인라인뷰) : 최종 결과를 구하기 위한 중간 단계 값 추출
-- 요건 : 최종 결과물 = 평균 주문 수, 최다 주문 횟수 추출

-- 중간 단계 구하기 : 회원별 주문 횟수
select o.customer_id
	 , count(*) as cnt	-- 회원별 주문 횟수
  from orders o			-- orders table : 주묵
 group by o.customer_id	-- 회원별
 order by o.customer_id
 

select avg(T.cnt) as 평균주문수
	 , max(T.cnt) as 최다주문수
  from ( -- from 절 select : 인라인 뷰(서브쿼리) => table
	select 
		   count(*) as cnt	
	  from orders o			
	 group by o.customer_id
	 order by o.customer_id
	)T;