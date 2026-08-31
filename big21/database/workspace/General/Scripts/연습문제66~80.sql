-- 66. 전체 평균가보다 비싼 상품 수  
select count(*)
  from products pr
 where pr.price > (
 		select avg(p.price)
		  from products p 
		)
;		
-- 67. 전체 평균가보다 비싼 상품 중 가장 싼 것
select pr."name", pr.price 
  from products pr
 where pr.price > (
 		select avg(p.price)
		  from products p 
		)
 order by pr.price 
 limit 1
;
-- 68. 각 분류에서 가장 비싼 상품 (분류 1~5만)
select p."name", t.max_price 
  from products p 
  join (select p.category_id, max(p.price) as max_price
	      from products p
	     where p.category_id <=5
	     group by p.category_id
		)t
    on t.category_id = p.category_id 
 where p.price = t.max_price 
;
-- 69. 전체 평균 주문액보다 큰 주문 몇 건?
select count(*)
  from orders ord
 where ord.total_amount > (
 	   select avg(o.total_amount)
	     from orders o)
;

-- 70. 주문 이력이 있는 VIP 수
select count(distinct o.customer_id)
  from orders o
  join (select c.customer_id as customer_id
  		  from customers c
 		 where c.grade = 'VIP')t
    on o.customer_id = t.customer_id
;   
select count(*) as cnt
  from customers c
 where c.grade = 'VIP'
   and exists (select 1 from orders o where o.customer_id = c.customer_id)
;

-- 71. 최고가 상품과 같은 분류에 속한 상품 몇 개?
select count(*)
  from products pr
 where pr.category_id = (select p.category_id
  						 from products p
 						order by p.price desc
 						limit 1)
;				
 						
-- 72. 회원 유효구매액 기준 고객군(초우량>=50만 / 우량>= 20만 / 일반) 인원
with customer_buy as (
select case when sum(o.total_amount) >= 5000000 then '초우량'
			when sum(o.total_amount) >= 2000000 then '우량'
			else '일반'
			end as customer_base
  from orders o
 where o.status not in ('취소', '환불')
 group by o.customer_id 
)
select cb.customer_base, count(*)
   from customer_buy cb
  group by 1
;

-- 73. 최고가와 같은 가격을 가진 상품 몇 개?
select count(*)
  from products p
 where p.price = (select p.price
		  		    from products p
				   order by p.price desc
				   limit 1)	
;

-- 74. 단종 상품이 하나도 없는 분류
(select c."name" 
  from categories c)
except
(select distinct c."name"
  from products p
  join categories c
    on p.category_id = c.category_id 
 where p.status in ('단종'))
 
-- 75. 판매 중 상품과 단종 상품이 모두 있는 분류
(select p.category_id
  from products p 
 where p.status = '판매중')
intersect
(select p.category_id
  from products p 
 where p.status = '단종')
;

-- 76. 월매출 평균
select avg(t.sum_total)
  from (
  		select date_trunc('month', o.order_date) as 월
	 		 , sum(o.total_amount) as sum_total 
  		  from orders o
 		 group by 1)t
;

-- 77. 총 구매액이 전체 회원 평균보다 큰 회원
with tot_sum as (
	select o.customer_id, sum(o.total_amount) as sum_tot
	  from orders o
	 group by o.customer_id
)
select count(distinct ts.customer_id)
  from tot_sum ts
 where ts.sum_tot > (select avg(tsum.sum_tot) from tot_sum tsum)

-- 78. 상품 가격의 중앙값
with div as (
	select p.price
		 , ntile(2) over(order by p.price) as nt
	  from products p 
)
select d.price
  from div d
 where nt = 1
 order by d.price desc
 limit 1
;

select percentile_cont(0.5) within group (order by price) as center_
  from products
;
 
-- 79. 평균가가 전체 평균가보다 높은 분류 몇 개?
with avg_price_category as (
select round(avg(p.price), 0) as avg_price
  from products p 
 group by p.category_id 
)
select count(*)
  from avg_price_category apc
 where apc.avg_price > ( select avg(p.price)
						   from products p)
;

-- 80. 주문액 상위 10% 경계값(90백분위)을 구하라.
with tot_sum as (
	select o.order_id
		 , sum(o.total_amount) as tas
		 , ntile(100) over (order by sum(o.total_amount)) as nt
	  from orders o 
	 group by o.order_id
) 
select distinct ts.tas
  from tot_sum ts
 where ts.nt = 90
 order by ts.tas
 limit 1
 
 select round(percentile_cont(0.9) within group (order by total_amount)) as p90
   from orders;