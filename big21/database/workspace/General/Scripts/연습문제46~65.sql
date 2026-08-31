
-- 46. product_id = 1 상품의 분류명
select c."name"
  from products p
  join categories c
    on c.category_id = p.category_id 
 where p.product_id = 1
;

-- 47. 분류명 '컴퓨터'인 상품 갯수
select c."name"
	 , count(*)
  from products p
  join categories c
    on p.category_id = c.category_id 
 where c."name" = '컴퓨터'
 group by c."name" 
;
 
-- 48. '컴퓨터'분류 상품의 평균 가격
select c."name"
	 , round(avg(p.price))
  from products p
  join categories c
    on p.category_id = c.category_id
 where c."name" = '컴퓨터'
 group by c."name"
;
 
--49. 분류별 매출 상위 5
select c."name" as category
	 , sum(oi.quantity*oi.unit_price) as sum_price
  from order_items oi
  join products p 
    on p.product_id = oi.product_id
  join categories c 
    on c.category_id = p.category_id
 group by category
 order by sum_price desc
 limit 5
;

-- 50. 상품별 총 판매수량 상위 5개
select p."name"
	 , sum(oi.quantity) as sum_quantity
  from order_items oi
  join products p 
    on p.product_id = oi.product_id 
 group by p."name" 
 order by sum_quantity desc
 limit 5
;

-- 51. 상품별 매출 상위 5
select p."name"
	 , sum(oi.unit_price * oi.quantity ) as sum_price
  from order_items oi 
  join products p
    on p.product_id = oi.product_id
 group by p."name"
 order by sum_price desc 
 limit 5

-- 52. 주문을 가장 많이 한 회원 5명 이름
select c."name"
	 , count(*) as cnt
  from orders o
  join customers c
    on c.customer_id = o.customer_id 
 group by c."name"
 order by cnt
 limit 5
;

-- 53. 총 구매액 상위 회원 5명
select c."name"
	 , sum(o.total_amount) as sum_total
  from orders o
  join customers c
    on c.customer_id = o.customer_id
 group by c.customer_id
 order by sum_total desc
 limit 5
;

--54. order_id = 12345 주문의 품목(상품명, 수량, 단가)
select p."name"
	 , oi.quantity
	 , oi.unit_price
  from order_items oi 
  join products p
    on oi.product_id = p.product_id
 where oi.order_id = 12345
 order by p."name"
;

-- 55. customer_id = 1 주문 수
select o.customer_id
	 , count(*)
  from orders o
 where o.customer_id = 1
 group by o.customer_id
;

-- 56. 분류별 주문 건수(중복 제거) 상위 5
select p.category_id
	 , count(distinct oi.order_id) as cnt
  from order_items oi 
  join products p
    on oi.product_id = p.product_id
  join categories c 
    on c.category_id = p.category_id
 group by p.category_id 
 order by cnt desc
 limit 5
;

-- 57. 매출이 가장 큰 분류 1개
select c."name"
	 , sum(oi.unit_price * oi.quantity ) as total_price
  from order_items oi
  join products p 
    on oi.product_id = p.product_id
  join categories c
    on p.category_id = c.category_id
 group by c."name" 
 order by total_price desc
 limit 1
;

-- 58. 분류별 '단종' 상품 수를 0 포함해 구하라

-- 59. 배송지 도시별 매출 상위 5
select o.shipping_city
	 , sum(oi.unit_price * oi.quantity) as total_price
  from order_items oi 
  join orders o 
    on oi.order_id = o.order_id
 group by o.shipping_city
 order by total_price desc
 limit 5
;

-- 60. vip 회원이 낸 주문 갯수
select count(*)
  from orders o
  join customers c 
    on o.customer_id = c.customer_id
 where c.grade = 'VIP'
;

-- 61. 등급별 평균 주문액
select c.grade
	 , round( avg(o.total_amount), 1)
  from orders o 
  join customers c 
    on o.customer_id = c.customer_id
 group by c.grade
;

-- 62. 2023년 상반기 월별 매출
select date_trunc('month', o.order_date)::date as date
	 , sum(o.total_amount)
  from orders o 
 where date_trunc('year', o.order_date) = date '2023-01-01'
   and date_trunc('month', o.order_date) < date '2023-07-01'
 group by 1
; 

--63. 상품별 평균 주문 수량 상위 5
select p."name", round(avg(oi.quantity), 2) as qty
  from order_items oi 
  join products p 
    on oi.product_id = p.product_id
 group by p."name"
 order by qty desc
 limit 5
;

-- 64. 한 번도 팔리지 않은 상품 수
select count(*)
  from products p 
  left join order_items oi 
    on p.product_id = oi.product_id
 where oi.product_id is null
 
select count(*)
  from products p 
 where not exists (
 	select 1 from order_items oi where oi.product_id=p.product_id
 )
 
-- 65. 주문 1건당 평균 품목 수
select avg(t.cnt) 
  from (
	select count(product_id) as cnt
	  from order_items oi 
	 group by oi.order_id) t