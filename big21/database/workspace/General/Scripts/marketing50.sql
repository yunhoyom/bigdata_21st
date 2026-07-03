-- 1. 취소, 환불을 제외한 전체 유효 주문 건수와 유효 매출 합계를 한 행으로 구하라
select count(*), sum(o.total_amount)
  from orders o 
 where o.status not in ('취소', '환불')
;

-- 2. 주문 상태별 주문 건수, 전체 대비 비율(%), 매출을 건수 내림차순으로 구하라
select o.status
	 , count(*) as cnt
	 , round(100 * count(*) / sum(count(*)) over(), 1) as ratio
	 , sum(o.total_amount )
  from orders o
 group by o.status 
 order by cnt desc
;

-- 3. 회원 등급별 회원 수와 전체 대비 비율(%)을 회원 수 내림차순으로 구하라
 select c.grade
 	  , count(*) as cnt
 	  , 100 * count(*) / sum(count(*)) over() as pct
   from customers c
  group by c.grade 
  order by cnt desc
;

-- 4. 활성/휴면 회원 수와 비율(%)을 구하라
select c.is_active
	 , count(*) as cnt
	 , 100 * count(*) / sum(count(*)) over() as ratio
  from customers c 
 group by c.is_active
;

-- 5. 회원 수가 가장 많은 상위 10개 도시를 회원 수와 함께 구하라
select c.city
	 , count(*) cnt
  from customers c
 group by c.city 
 order by cnt desc
 limit 5
;

-- 6. 가입 연도별 신규 회원 수를 오름차순으로 구하라
select extract(year from c.signup_date)
	 , count(*) as cnt
  from customers c 
 group by 1
 order by 2
;

-- 7. 상품 판매별(판매중/품절/단종) 상품 수와 비율(%)을 구하라
select p.status
	 , count(*) as cnt
	 , 100 * count(*) / sum(count(*)) over() as ratio
  from products p
 group by p.status
;
 
-- 8. 5만/10만/20만/30만원 경계로 가격대를 5구간으로 나눠 구간별 상품 수를 구하라
select case when p.price <= 50000 then '5만 미만'
			when p.price <= 100000 then '5~10만'
			when p.price <= 200000 then '10~20만'
			when p.price <= 300000 then '20~30만'
			else '30만 이상'
			end
	 , count(*) as cnt
  from products p
 group by 1
 order by cnt desc
;

-- 9. 카테고리별 매출(수량x주문시점단가)과 판매수량을 매출 내림차순으로 구하라(취소, 환불 제외)
select p.category_id
	 , sum(oi.quantity * oi.unit_price) as sum_profit
	 , count(*) as cnt
  from order_items oi 
  join products p 
    on oi.product_id = p.product_id
  join orders o 
    on oi.order_id = o.order_id
 where o.status not in ('취소', '환불')
 group by p.category_id 
 order by sum_profit desc
;

-- 10. 판매수량 기준 베스트셀러 상품 
with sell_cnt as (
	 select oi.product_id
		 , count(*) as cnt
	  from order_items oi
	 group by oi.product_id
	 order by cnt desc
	 limit 10
)
select sc.product_id
	 , p.name
	 , sc.cnt
  from sell_cnt as sc
  join products p 
    on p.product_id = sc.product_id
 order by cnt desc
;

-- 11. 매출액 기준 효자 상품 top 10
with sell_price as (
	select oi.product_id, sum(oi.unit_price * oi.quantity ) as sum_profit
	  from order_items oi 
	 group by oi.product_id
	 order by sum_profit desc
	 limit 10
)
select sp.product_id
	 , p.name
	 , sp.sum_profit 
  from sell_price as sp
  join products p 
    on sp.product_id = p.product_id
 order by sp.sum_profit desc
;

-- 12. 월(YYYY-MM)별 주문 건수와 매출을 시간 순으로 구하라
select date_trunc('month', o.order_date)::date
	 , count(*) as cnt
	 , sum(o.total_amount ) as profit_month
  from orders o 
 group by 1
 order by 1
;

-- 13. 요일(일~토)별 주문 건수와 매출을 요일 순서대로 구하라
select extract(dow from o.order_date)
	 , case when extract(dow from o.order_date) = 0 then '일'
			when extract(dow from o.order_date) = 1 then '월'
			when extract(dow from o.order_date) = 2 then '화'
			when extract(dow from o.order_date) = 3 then '수'
			when extract(dow from o.order_date) = 4 then '목'
			when extract(dow from o.order_date) = 5 then '금'
			else '토' end as week
	 , count(*)
	 , sum(o.total_amount)
  from orders o
 group by 1
 order by 1
;

-- 14. 시간대(0~23)별 주문 건수 상위 10개
select extract(hour from o.order_date)
	 , count(*) as cnt
  from orders o 
 group by 1
 order by 2 desc
 limit 10
;

-- 15. 배송지역별 주문 건수, 매출 상위 10개를 구하라
select o.shipping_city
	 , count(*) as cnt
	 , sum(o.total_amount)
  from orders o 
 group by o.shipping_city
 order by 3 desc 
 limit 10
;

-- 16. 성별 x 카테고리별 매출을 성별, 매출 내림차순으로 구하라
select c.gender
	 , ca.name
	 , sum(o.total_amount) as tot_sum
  from customers c 
  join orders o
    on c.customer_id = o.customer_id
  join order_items oi
    on o.order_id = oi.order_id
  join products p 
    on oi.product_id = p.product_id
  join categories ca
    on p.category_id = ca.category_id
 group by c.gender, ca.name
 order by c.gender desc, tot_sum desc
 
--17. 누적 유효 매출 상위 고개 20명을 이름, 등급, 주문 수와 함께 구하라
with top_20 as (
 select o.customer_id 
	 , sum(o.total_amount ) as sum_tot
	 , count(o.order_id ) as cnt
  from orders o
 where o.status not in ('취소', '환불')
 group by o.customer_id
 order by 2 desc 
 limit 10
)
select c.name
	 , c.grade 
	 , t.cnt
  from top_20 t
  join customers c 
    on t.customer_id = c.customer_id
 order by cnt desc
; 

-- 18. 회원 등급별 주문 건수와 평균 객단가(AOV)를 객단가 내림차순으로 구하라
select c.grade
	 , count(o.order_id) as cnt
	 , round(avg(o.total_amount), 0) as amount_avg
  from orders o 
  join customers c 
    on o.customer_id = c.customer_id
 group by c.grade
 order by amount_avg desc
; 

-- 19. 2회 이상 구매한 재구매 고객 수, 전체 구매 고객 수, 재구매율(%)을 구하라
with buy as (
	select count(*) as cnt
	  from orders o 
	 group by o.customer_id
	having count(*) > 2
)
select count(b.cnt) as twice
	 , (select count(distinct o2.order_id) from orders o2) as whole
	 , 100 * count(b.cnt) / (select count(distinct o2.order_id) from orders o2) as pct
  from buy b
;  
-- 20. 구매 횟수 구간(1,2,3,4,5,6회+)별 고객 수
with buy as (
	select count(*) as cnt
	  from orders o 
	 group by o.customer_id
)
select case when b.cnt = 1 then '1회'
			when b.cnt = 2 then '2회'
			when b.cnt = 3 then '3회'
			when b.cnt = 4 then '4회'
			when b.cnt = 5 then '5회'
			when b.cnt >= 6 then '6회'
			when b.cnt < 1 then '0회'
			 end as tno
	 , count(*)
  from buy b
 group by 1
 order by 1
;

-- 21. 고객별 r,f,m을 각 5분위 점수화하고(r,f,m) 조합별 고객 수 상위 10개
with total as (
	select o.customer_id
		 , max(o.order_date ) as ret
		 , count(*) as fre
		 , sum(o.total_amount) as mon
	  from orders o
	 group by o.customer_id
),
rfm as (
	select t.customer_id
		 , ntile(5) over(order by t.ret) as r
		 , ntile(5) over(order by t.fre) as f
		 , ntile(5) over(order by t.mon) as m
	  from total t
)
select rfm.r
	 , rfm.f 
	 , rfm.m 
	 , count(*) as cnt
  from rfm
 group by r, f, m
 order by cnt desc
 limit 10
;

-- 22. 월별 매출을 신규 고객(첫 주문 달)과 기존 고객(그 이후)으로 나눠 구하라
with first_order as(
	select o.customer_id
		 , min(o.order_date) as m
	  from orders o
	 group by o.customer_id
)
select date_trunc('month', o.order_date)::date as month
	 , sum(o.total_amount) filter(where date_trunc('month',fo.m)::date = date_trunc('month',o.order_date)::date) as first
	 , sum(o.total_amount) filter(where date_trunc('month',fo.m)::date < date_trunc('month',o.order_date)::date) as not_first
	 , sum(o.total_amount)
  from first_order fo
  join orders o
    on o.customer_id = fo.customer_id
 group by 1
 order by 1
;

---------------- 23. 첫 구매월 코호트별 m0, m3, m6, m12 재구매 고객 수
with first_order as(
	select o.customer_id
		 , date_trunc('month', min(o.order_date))::date as m
	  from orders o
	 group by o.customer_id
)
select count(*) filter(where date_trunc('month', o.order_date)::date = fo.m) as month
	 , count(*) filter(where date_trunc('month', o.order_date)::date = fo.m + interval '3 months') as three_month
	 , count(*) filter(where date_trunc('month', o.order_date)::date = fo.m + interval '6 months') as six_month
	 , count(*) filter(where date_trunc('month', o.order_date)::date = fo.m + interval '12 months') as twelve_month
  from first_order fo
  join orders o
    on o.customer_id = fo.customer_id
;

-- 24. 마지막 주문 후 180일 초과 + 누적매출 100만 원 이상인 이탈 위험 우수 고객 20명
with cond as (
	select o.customer_id 
		 , MIN(o.order_date) as latest
		 , sum(o.total_amount) as tot_amt
	  from orders o 
	 group by o.customer_id 
)
select cu."name" 
	 , c.latest
	 , c.tot_amt
	 , (now() - interval '180 days')::date
  from cond c
  join customers cu
    on c.customer_id = cu.customer_id
 where c.latest < now() - interval '180 days'
   and c.tot_amt > 1000000
 order by c.tot_amt desc
 limit 20
;

-- 25. 카테고리별 매출, 매출 비중(%), 누적 비중(%)을 매출 내림차순으로 구하라.
select p.category_id
	 , sum(oi.unit_price * oi.quantity ) as uni_qua
	 , 100* sum(oi.unit_price * oi.quantity ) / sum(sum(oi.unit_price * oi.quantity )) over() as uni_qua_ratio
	 , 100* sum(oi.unit_price * oi.quantity ) / sum(sum(oi.unit_price * oi.quantity )) over(order by sum(oi.unit_price * oi.quantity ) desc) as ratio_acc
  from order_items oi 
  join products p 
    on oi.product_id = p.product_id
 group by p.category_id 
;

-- 26. 카테고리별 매출 1위 상품을 각 1개씩 구하라
with rnk as(
	select oi.product_id
		 , p.category_id
		 , sum(oi.unit_price * oi.quantity) as profit
		 , rank() over(partition by p.category_id order by sum(oi.unit_price * oi.quantity) desc) as rn
	  from order_items oi
	  join products p 
	    on oi.product_id = p.product_id
	 group by p.category_id, oi.product_id
)
select r.category_id
	 , p."name"
	 , r.profit
  from rnk r
  join products p
    on p.product_id = r.product_id
 where r.rn = 1
;

	 , lag(sum(o.total_amount )) over(order by date_trunc('month', o.order_date )::date )

-- 27. 월별 매출과 전월 매출, 전월 대비 증감률(%)을 구하라
with res as (
	select date_trunc('month', o.order_date )::date as months
		 , sum(o.total_amount ) as profit_mon
	  from orders o 
	 group by 1
)
select r.months
	 , r.profit_mon 
	 , r.profit_mon - lag(r.profit_mon ) over(order by r.months) as pct
  from res r
;

-- 28. 회원 등급별 구매 고객 수, 1인당 평균 주문수, 1인당 평균 매출을 구하라
select c.grade
	 , count(distinct o.customer_id) as count
	 , count(o.order_id) / count(distinct o.customer_id) as count_avg
	 , sum(o.total_amount) / count(distinct o.customer_id) as avrg
  from orders o
  join customers c 
    on o.customer_id = c.customer_id
 group by c.grade
;

--29. 연령대별(10대 이하~60대 이상) 주문 수와 매출을 구하라
select case when extract(year from age(current_date, c.birth_date)) < 20 then '10대 이하'
			when extract(year from age(current_date, c.birth_date)) < 30 then '20대'
			when extract(year from age(current_date, c.birth_date)) < 40 then '30대'
			when extract(year from age(current_date, c.birth_date)) < 50 then '40대'
			when extract(year from age(current_date, c.birth_date)) < 60 then '50대'
			else '60대 이상' end as rnge
	 , count(o.order_id) as tnoo
	 , count(o.total_amount) as profit
  from orders o 
  join customers c
    on o.customer_id = c.customer_id
 group by 1
;

-- 30. 같은 주문에 함께 담긴 상품 쌍 상위 10개(동시 구매 주문 수)를 구하라
select oi1.order_id
	 , count(oi1.product_id )
  from order_items oi1
  join order_items oi2
    on oi1.order_id = oi2.order_id
 where oi1.product_id < oi2.product_id