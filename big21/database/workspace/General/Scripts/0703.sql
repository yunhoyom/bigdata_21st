explain analyze select *
   from order_items oi
  where oi.product_id = 30
;

-- index 생성
create index order_items_product_id_idx
on order_items(product_id)
;


select *
  from order_items oi
 where oi.product_id = 30
;

select *
from (
	select c.customer_id 
		 , c."name" 
		 , count(o.customer_id) as order_cnt
		 , sum(o.total_amount) as tot_amt
	  from customers c
	  left join orders o
	    on c.customer_id = o.customer_id
	 group by c.customer_id, c."name" 
	-- order by order_cnt desc
)
 where tot_amt is null
;

create view customer_order_summary as
	select c.customer_id 
		 , c."name" 
		 , count(o.customer_id) as order_cnt
		 , sum(o.total_amount) as tot_amt
	  from customers c
	  left join orders o
	    on c.customer_id = o.customer_id
	 group by c.customer_id, c."name" 
;

select *
  from customer_order_summary cos
 where cos.tot_amt is not null
 order by cos.tot_amt desc, cos.order_cnt desc
;