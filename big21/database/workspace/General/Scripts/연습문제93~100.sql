-- 93. 2023년 상반기 월별 매출 추세(월, 매출, 누적, 전월대비) 한 번에 구하라.
with total_amount_mon as (
	select date_trunc('month', o.order_date) as month
		 , sum(o.total_amount) as total_sum
	  from orders o
	 where extract(year from o.order_date)::int = 2023
	   and extract(month from o.order_date)::int between 1 and 6
	 group by date_trunc('month', o.order_date)
)
select tam.month
	 , tam.total_sum
	 , sum(tam.total_sum) over(order by tam.month) as running_total
	 , tam.total_sum - lag(tam.total_sum) over(order by tam.month) as comp_last_mon
  from total_amount_mon tam
;

--94. 분류별 매출과 전체 대비 비중(%)
with total as (
	select p.category_id
		 , sum(oi.unit_price * oi.quantity) as sum_tot
	  from order_items oi
	  join products p 
	    on oi.product_id = p.product_id
	 group by p.category_id
)
select t.category_id
	 , t.sum_tot
	 , round(100 * t.sum_tot / sum(t.sum_tot) over(), 2)
  from total t
;

-- 95. 매출 상위 10개 상품이 전체 매출에서 차지하는 비중
with st as (
select oi.product_id
	 , sum(oi.unit_price * oi.quantity) as sum_tot
  from order_items oi 
 group by oi.product_id
)
, ten as (
	select oi.product_id
		 , oi.sum_tot as sum_tt 
	  from st oi 
	 order by sum_tot desc
	 limit 10
)
select 100 * sum(s.sum_tt) / (select sum(s.sum_tot) from st s)
  from ten s

-- 96. 2024년에 가입한 신규 회원 수
select count(*)
  from customers c
 where extract(year from c.signup_date)::int = 2024
 
-- 97. 주문을 2건 이상 한 회원은 몇 명?
select count(*)
  from (
		select o.customer_id
		  from orders o
		 group by o.customer_id
		having count(o.order_id) >= 2
  )
;  

-- 98. 매출 누적 비중이 80% 이하에 드는(상위 20%) 상품은 몇 개인가?
with perc as (
	select oi.product_id
		 , sum(oi.unit_price * oi.quantity) as m
--		 , percent_rank() over(order by sum(oi.unit_price * oi.quantity)) as per
	  from order_items oi
	 group by oi.product_id
)
select m
	 , sum(m) over(order by m)
  from perc p
;

-- 99. 가입 연,월별 회원 수 상위 5개월
(select extract(year from c.signup_date)::varchar as sign_year
	 , count(*) as cnt
  from customers c
 group by 1
 order by cnt desc
 limit 5)
union
(select (date_trunc('month', c.signup_date)::date)::varchar as sign_year
	 , count(*) as cnt
  from customers c
 group by 1
 order by cnt desc
 limit 5)
 
-- 100. 등급별 회원수, 주문수, 객단가
select c.grade
	 , count(*)
	 , count(o.order_id)
	 , round(avg(o.total_amount ),1)
  from orders o
  join customers c
    on o.customer_id = c.customer_id
 group by c.grade 