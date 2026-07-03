-- 문제 1 : 등급이 GOLD, 도시가 '서울'인 회원은 몇 명?
select count(*)
  from customers c
 where c.grade = 'GOLD'
   and c.city = '서울'
;
-- 하나씩 주석하고 확인해서 검증해 보기.

-- 문제 2 : 가장 저렴한 상품 3개의 이름과 가격(가격 동일시 product_id 오름차순)
select p."name", p.price
  from products p
 order by p.price, p.product_id 
 limit 3
;

-- 문제 3 : 세금(10%) 포함가가 50만원을 넘는 상품은 몇 개?
select count(*)
  from products p
 where p.price * 1.1 > 400000
;

-- 문제 4 : 성별별 회원 수
select c.gender, count(*)
  from customers c
 group by c.gender 
 
-- 문제 5 : 회원 수가 3000명 넘는 도시는 몇 개?
with city_customers as (
	select c.city, count(*) as cnt
  	  from customers c
 	 group by c.city
)
select count(*)
  from city_customers cc
 where cc.cnt > 3000
;

select c.city, count(*)
  from customers c
 group by c.city 
having count(*) > 3000
;

-- 문제 6 : 평균가가 가장 낮은 분류의 category_id와 평균가
select p.category_id, round(avg(p.price),0) as avg_price
  from products p
 group by p.category_id
 order by avg_price
 limit 1
 
-- 문제 7 : 분류명이 '컴퓨터'인 상품 갯수
select count(*)
  from products p
  join categories c
    on p.category_id = c.category_id
 where c."name" = '컴퓨터'
 
-- 문제 8 : 총 판매 수량이 가장 많은 상품 top3의 product_id와 수량
with top as (
	select oi.product_id
		 , sum(oi.quantity) as sum_quantity
	  from order_items oi
	 group by oi.product_id
	 order by sum_quantity desc
	 limit 3
)
select t.product_id, p."name", t.sum_quantity
  from top t
  join products p
    on t.product_id = p.product_id
;
 
-- 문제 9 : 최고가와 동일한 가격을 가진 상품
select count(*)
  from products pr
 where pr.price = (select p.price
				     from products p 
 				    order by p.price desc
 					limit 1)
;

select count(*)
  from products pr
 where pr.price = (select max(p.price)
				     from products p)
;				     -- max 구하기 위해 항상 1000번씩 계산하여 1000*1000

select count(*)
  from products p1
  join (select max(p.price) as m_p from products p) p2
    on p1.price = p2.m_p
-- 2000번?
    
-- 문제 10 : 전체 회원을 가입일 순으로 4분위로 나눌 때 1분위의 회원 수
with ntiles as (
	select ntile(4) over(order by c.signup_date asc) as ntile
	  from customers c
)
select count(*)
  from ntiles n
 where n.ntile = 1
;