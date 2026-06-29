-- 23. 등급별 회원 수
select c.grade, count(*) as cnt
  from customers c 
 group by c.grade 
;

-- 24. 회원이 가장 많은 도시 5곳
select c.city
	 , count(*) as cnt
  from customers c 
 group by c.city 
 order by cnt desc
 limit 5
;

-- 25. 성별별 회원 수
select c.gender
	 , count(*) as cnt
  from customers c 
 group by c.gender
;

-- 26. 상품 상태별 개수
select p.status
	 , count(*) as cnt
  from products p
 group by p.status 
;

-- 27. 분류(category_id)별 상품 수
select p.category_id
	 , count(*) as cnt
  from products p 
 group by p.category_id 
;

-- 28. 분류별 평균 가격(반올림)
select p.category_id
	 , round(avg(p.price),0)
  from products p
 group by p.category_id 
;

-- 29. 전체 상품 평균, 최저, 최고 가격
select avg(p.price)
	 , min(p.price)
	 , max(p.price)
  from products p
;

-- 30. 등급별 가장 나이 많은 회원 생년월일
select c.grade
	 , min(c.birth_date)
  from customers c 
 group by c.grade
;

-- 31. 2023 상반기(1~6월) 월별 주문 건수
select date_trunc('month', o.order_date)::date as month, count(*)
  from orders o
 group by 1 
 order by 1
 limit 6
;

-- 32. 연도별 주문 건수
select date_trunc('year', o.order_date )::date as year, count(*)
  from orders o 
 group by 1
 order by 1
;

-- 33. 주문 상태별 건수
select o.status
	 , count(*)
  from orders o
 group by o.status
;

-- 34. 배송지별 주문 수 상위 5곳
select o.shipping_city
	 , count(*)
  from orders o 
 group by o.shipping_city 
 order by count(*) desc
 limit 5
;

-- 35. 가격대(저: 5만 미만 / 중: 20만 미만 / 고)별 상품 수
select case when p.price < 50000 then '저가'
			when p.price < 200000 then '중가'
			else '고가'
			end as price_range
	 , count(*)
  from products p 
 group by 1
;

-- 36. 상품 수 72개인 분류는 몇 개?
select count(T.id)
  from  (select p.category_id as id
  			  , count(*) as cnt
  		   from products p 
 		  group by p.category_id)T
 where T.cnt = 72
;

-- 37. 평균가가 185,000원 이상인 분류 몇 개?
--select count(p.category_id)
--  from products p 
-- group by p.category_id 
--having 

select count(*)
from (select p.category_id
  		from products p
 	   group by p.category_id
 	  having avg(price) >= 185000)T
;
 

-- 38. 등급별 회원 비율(%)
select c.grade
	 , count(*)*100 / sum(count(*)) over() as percent
  from customers c 
 group by c.grade
;
 
-- 39. 재고 합계가 가장 큰 분류 5곳
select c."name", sum(p.stock_quantity) as cnt
  from products p 
  join categories c
    on c.category_id = p.category_id 
 group by c."name" 
 order by cnt desc
 limit 5
;
 
-- 40. 분류별 최고가
select p.category_id, max(p.price)
  from products p
 group by p.category_id
 order by p.category_id 
;
 
-- 41. 가입 연도별 회원 수
select date_trunc('year', c.signup_date)::date as sign_year
	 , count(*)
  from customers c
 group by sign_year
 order by sign_year
;
 
--42. 출생 연대(10년 단위)별 회원 수
select trunc(extract(year from c.birth_date), -1) as decade
	 , count(*) as cnt
  from customers c
 group by 1
 order by 1
;
  
--43. 분류별 '판매중'상품 수 상위 6개 분류
select p.category_id, count(*) as cnt
  from products p
 where p.status = '판매중'
 group by p.category_id
 order by cnt desc
 limit 6
;

--44. 요일별 주문 수
select extract(dow from order_date)::int as week
	 , count(*) as cnt
  from orders o
 group by 1
 order by 1
;

--45. 평균가가 높은 분류 3곳
select p.category_id, round(avg(p.price), 1) as avg_price
  from products p 
 group by p.category_id
 order by avg_price desc
 limit 3
 
 
  select * from pg_proc where proname = 'date_trunc' limit 5;
  

  