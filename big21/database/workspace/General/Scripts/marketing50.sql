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
select oi1.product_id 
	 , oi2.product_id 
	 , count(*) as cnt
  from order_items oi1
  join order_items oi2
    on oi1.order_id = oi2.order_id
 where oi1.product_id < oi2.product_id
 group by oi1.product_id, oi2.product_id
 order by cnt desc
 limit 10
;

-- 31. 월별 매출과 전년 동월 매출, 전년 동월 대비(YoY) 쯩감률(%)을 구하라
select date_trunc('month', o.order_date)::date
	 , sum(o.total_amount ) as this_year
	 , lag(sum(o.total_amount), 12) over(order by date_trunc('month', o.order_date)::date) as last_year
	 , 100 * sum(o.total_amount ) / lag(sum(o.total_amount), 12) over(order by date_trunc('month', o.order_date)::date)-100 as YoY_pct
  from orders o
 group by 1
;

-- 32. 분기별 주문 건수, 매출과 전체 대비 분기 비중(%)을 구하라
with calendar as (
	select o.order_date
		 , date_trunc('quarter', o.order_date)::date as q
		 , o.total_amount
	  from orders o
  )
select extract(year from c.q) || case when extract(month from c.q)::int <= 3 then 'Q1'
									  when extract(month from c.q)::int <= 6 then 'Q2'
									  when extract(month from c.q)::int <= 9 then 'Q3'
									  when extract(month from c.q)::int <= 12 then 'Q4' end as year_q
	 , count(*) as cnt
	 , sum(c.total_amount) as profit
	 , 100 * sum(c.total_amount) / sum(sum(c.total_amount)) over() as pct
  from calendar c
 group by 1
 order by 1
;

-- 33. 카테고리별 취소, 환불 매출률(%)을 높은 순으로 구하라
select p.category_id
	 , sum(oi.quantity * oi.unit_price) as total
	 , sum(oi.unit_price * oi.quantity) filter(where o.status in ('취소', '환불')) as cancel_refund
	 , 100 * sum(oi.unit_price * oi.quantity) filter(where o.status in ('취소', '환불')) / sum(oi.quantity * oi.unit_price) as pct
  from order_items oi 
  join orders o
    on o.order_id = oi.order_id
  join products p 
    on oi.product_id = p.product_id
 group by p.category_id
 order by 4 desc
;

-- 34. 일별 매출과 7일 이동평균을(앞 15일) 구하라
with profit as (
	select o.order_date::date as od
		 , sum(o.total_amount ) as ta
	  from orders o
	 group by 1
)
select p.od
 	 , p.ta 
	 , round(avg(p.ta) over(order by p.od rows between 6 preceding and current row), 1) as ma
  from profit p
 order by 1 desc
 limit 15
;

-- 35. 월별 매출과 연도 내 누적 매출(YTD)을 구하라
select date_trunc('month', o.order_date)::date
	 , sum(o.total_amount )
	 , sum(sum(o.total_amount)) over(partition by date_trunc('year', date_trunc('month', o.order_date)::date) order by date_trunc('month', o.order_date)::date)
  from orders o
 group by 1
;

-- 36. 월별 주문 수와 객단가(AOV) 추이를 구하라
select date_trunc('month', o.order_date)::date
	 , count(*) as cnt
	 , round(sum(o.total_amount ) / count(*), 1) as per_unit
  from orders o
 group by 1
 order by 1
;

-- 37. 미배송(결제완료+배송중) 주문이 많은 지역 상위 10개
select c.city
	 , count(*) as cnt
  from orders o 
  join customers c 
    on o.customer_id = c.customer_id
 where o.status in ('결제완료', '배송중')
 group by c.city
 order by cnt desc
 limit 10
;

-- 38. RFM 점수를 기준으로 고객을 명명된 세그먼트로 분류하고 세그먼트별 고객 수를 구하라
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
select case when r.r>=4 and r.f>=4 and r.m>=4 then '핵심VIP'
			when r.r>=4 and r.f>=4 then '충성'
			when r.r>=5 and r.f<=2 and r.m<=2 then '신규, 활성'
			when r.r<=3 and r.f>=4 then '이탈위험'
			when r.r<=2 then '휴면, 이탈'
			else '일반' end as cg
	 , count(*)
  from rfm r
 group by 1
;

-- 39. 첫 유효주문 기준 월별 신규 획득 고객 수를 구하라
with fir as (
	select o.customer_id
		 , min(o.order_date) as first_order
	  from orders o
	 group by o.customer_id 
)
select date_trunc('month', f.first_order)::date
	 , count(*)
  from fir f
 group by 1
 order by 1
  
-- 40. 지역 x 등급 교차표(회원 수)를 합계 상위 10개 지역으로 구하라
select c.city
	 , count(*) filter(where grade='VIP') as vip_cnt
	 , count(*) filter(where grade='GOLD') as gold_cnt
	 , count(*) filter(where grade='SILVER') as silver_cnt
	 , count(*) filter(where grade='BRONZE') as bronze_cnt
  from customers c 
 group by c.city 
;

-- 41. 연령대 x 성별 매출 교차표
select trunc(extract(year from age(c.birth_date)) / 10)*10 || case when c.gender = 'F' then '대 여성'
																   when c.gender = 'M' then '대 남성' end as r
	 , sum(o.total_amount)
  from customers c
  join orders o
    on o.customer_id = c.customer_id
 group by 1
 order by 2 desc
;
  
-- 42. 고객별 최대 매출 카테고리(대표 카테고리)의 고객 수 분포를 구하라
with cus_cate as( 
select o.customer_id
	 , p.category_id 
	 , sum(oi.unit_price * oi.quantity ) as profit
	 , row_number() over(partition by customer_id order by sum(oi.unit_price * oi.quantity ) desc ) as rn
  from orders o
  join order_items oi 
    on o.order_id = oi.order_id
  join products p
    on oi.product_id = p.product_id
 group by o.customer_id, p.category_id 
 order by o.customer_id
)
select c."name"
	 , count(*)
  from cus_cate cc
  join categories c
    on c.category_id = cc.category_id 
 where cc.rn = 1
 group by c."name" 
;

-- 43. 휴면(비활성) 회원 중 누적매출 100만원 이상 우수고객 20명을 구하라.
with deact as (
	select o.customer_id
		 , sum(o.total_amount) as tot_amt
	  from orders o
	  join customers c 
	    on c.customer_id = o.customer_id
	 where c.is_active in ('false')
	 group by 1
)
select d.customer_id
	 , d.tot_amt
  from deact d
 where d.tot_amt >= 1000000
 order by d.tot_amt desc
 limit 20
;

-- 44. 유효 주문이 한 건도 없는 회원 수와 비율(%)
select count(*)
	 , count(*) / (select count(*) from customers c2) * 100 as pct
  from customers c
  left join orders o
    on c.customer_id = o.customer_id
 where o.customer_id is null
;  

-- 45. 유효 판매량이 가장 적은 판매 부진(데드스톡 후보) 상품 하위 10개
select p.product_id
	 , sum(coalesce(oi.quantity ,0)) as qty
  from products p
  left join order_items oi
    on p.product_id = oi.product_id 
 group by p.product_id 
 order by 2
 limit 10
;

-- 46. 재고가 많은데 판매량이 적은 과잉재고 위험 상품(판매중) 10개
with dead_stock as (
	select p.product_id
		 , sum(coalesce(oi.quantity ,0)) as qty
	  from products p
	  left join order_items oi
	    on p.product_id = oi.product_id
	 group by p.product_id 
)
select p.product_id
	 , p.stock_quantity
	 , ds.qty
  from dead_stock ds
  join products p
    on ds.product_id = p.product_id
 where p.status = '판매중'
 order by p.stock_quantity desc, ds.qty
;

-- 47. 상품 상태별(판매중/품절/단종) 과거 매출과 매출 비중(%)을 구하라
select p.status
	 , sum(oi.unit_price * oi.quantity) as profit_category
	 , sum(oi.unit_price * oi.quantity) / sum(sum(oi.unit_price * oi.quantity)) over() * 100 as pct
  from products p
  join order_items oi
    on oi.product_id = p.product_id 
 group by p.status 
;

-- 48. 카테고리별 상품 수, 매출, 상품당 평균 매출(효율)을 효율 내림차순으로 구하라
select p.category_id
	 , count(distinct p.product_id) as cnt
	 , sum(oi.unit_price * oi.quantity) as profit_category
	 , round(sum(oi.unit_price * oi.quantity) / count(distinct p.product_id), 1) as avg_profit 
  from products p
  join order_items oi 
    on p.product_id = oi.product_id
 group by p.category_id
 order by 3 desc
;

-- 49. 동일 상품을 2회 이상 구매한 고객이 많은 상품 top 10
with ord_product as(
	select o.customer_id 
		 , oi.product_id 
		 , concat(o.customer_id, '|', oi.product_id) as cnt
	  from orders o 
	  join order_items oi 
	    on o.order_id = oi.order_id
),
cnt_ov as (
	select op.customer_id 
		 , op.product_id
		 , count(op.cnt) as cnt2
	  from ord_product op
	 group by op.customer_id , op.product_id
)
select co.product_id
	 , count(co.cnt2)
  from cnt_ov as co
 where co.cnt2 >= 2
 group by co.product_id
 order by 2 desc
 limit 10
;

-- 50. 상품을 누적 매출 비중으로 A/B/C 등급으로 분류하고 등급별 상품 수, 매출, 비중(%)을 구하라
with div_3 as(
	select p.product_id
		 , p."name"
		 , sum(oi.unit_price * oi.quantity) as prof
		 , ntile(3) over(order by sum(oi.unit_price * oi.quantity) ) as three
	  from products p
	  join order_items oi 
	    on oi.product_id = p.product_id
	 group by p.product_id
)
select case when d.three = 1 then 'C'
			when d.three = 2 then 'B'
			else 'A' end as grade
	 , count(*)
	 , sum(d.prof)
	 , 100 * sum(d.prof) / sum(sum(d.prof)) over()
  from div_3 d
 group by 1
;