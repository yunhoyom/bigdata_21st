-- 81. 분류별 가격 Top3(분류 1~2만)
with rnk as (
	select p.category_id
		 , p."name"
		 , p.price
		 , rank() over(partition by p.category_id order by p.price desc) as r
	  from products p
)
select *
  from rnk r
 where r.category_id in (1,2)
   and r <=3
;
-- 82. 전체 상품 가격 순위 1~5
with price_rnk as (
   select p."name"
	 , p.price
	 , row_number() over(order by p.price desc) as rn
  from products p
)
select pr."name" 
	 , pr.price
	 , pr.rn 
  from price_rnk pr
 where pr.rn <=5
;
-- 83. 2023 상반기 월매출 누적합
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
	 , sum(tam.total_sum) over(order by tam.month)
  from total_amount_mon tam
;
-- 84. 2023 상반기 월매출 전월대비 증감
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
	 , tam.total_sum - lag(tam.total_sum) over(order by tam.month) as comp_last_mon
  from total_amount_mon tam
;

-- 85. 상품을 가격 사분위로 나눠 분위별 상품 수, 가격범위 구하기
with nt as (
select p.price 
	 , ntile(4) over(order by p.price) as nt
  from products p
)
select n.nt, count(*), min(n.price), max(n.price)
  from nt n
 group by n.nt
 order by n.nt
;
-- 86. 분류 1번 안에서 각 상품의 가격비중(%) 상위 5
select p."name" 
	 , p.price
	 , round(100.0 * p.price / sum(p.price) over (partition by p.category_id), 3) as 분류내용
  from products p
 where p.category_id = 1
 order by p.price desc
 limit 5
;  
-- 87. 회원 총구매액을 십분위로 나눠 분위별 인원, 구매액 범위
with nt as (
	select o.customer_id
		 , sum(o.total_amount) as tot_sum
		 , ntile(10) over(order by sum(o.total_amount)) as ten_nt
	  from orders o
	 group by o.customer_id
)
select n.ten_nt 
	 , count(*)
	 , min(tot_sum)
	 , max(tot_sum)
  from nt n
 group by n.ten_nt 
 order by n.ten_nt
;

-- 88. 분류 1번에서 각 상품 가격이 분류 평균과 얼마나 차이나는지 상위 5
select p."name"  
	 , p.price
	 , avg(p.price) over()
	 , p.price - avg(p.price) over() as 편차
  from products p 
 where p.category_id = 1
 order by 편차 desc
 limit 5

-- 89. 가입 연도별 누적 회원 수
with year_sign as (
select extract(year from c.signup_date) as per_year
	 , count(*) as cnt
  from customers c
 group by 1
)
select ys.per_year
	 ,  ys.cnt
	 , sum(ys.cnt) over(order by ys.per_year)
  from year_sign ys
; 
--90. 가격 동률을 함께 묶는 순위로 상위 5행
select p."name" 
	 , p.price
	 , dense_rank() over(order by p.price desc)
  from products p 
 limit 5
;

-- 91. 가격 내림차순에서 바로 다음 상품과의 가격차이를 상위 5개
select p."name" 
	 , p.price
	 , p.price - lead(p.price ) over(order by p.price desc) as diff
  from products p
 limit 5
;

-- 92. 분류 1번에서 가격 백분위(percent_rank)가 0.9이상인 상위 상품
with pr as (
select p."name" 
	 , p.price
	 , percent_rank() over(order by p.price) as p_rnk
  from products p 
 where p.category_id = 1
)
select p."name" 
	 , p.price
	 , p.p_rnk 
  from pr p
 where p.p_rnk >= 0.9