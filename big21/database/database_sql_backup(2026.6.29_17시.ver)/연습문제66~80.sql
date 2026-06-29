-- 66. 전체 평균가보다 비싼 상품 수  
select count(*)
  from products pr
 where pr.price > (
 		select avg(p.price)
		  from products p 
		)
		
-- 67. 전체 평균가보다 비싼 상품 중 가장 싼 것
select pr."name", pr.price 
  from products pr
 where pr.price > (
 		select avg(p.price)
		  from products p 
		)
 order by pr.price 
 limit 1
 
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
 
-- 69. 전체 평균 주문액보다 큰 주문 몇 건?
select count(*)
  from orders ord
 where ord.total_amount > (
 	   select avg(o.total_amount)
	     from orders o)