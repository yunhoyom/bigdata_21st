select s.customer_id
	 , count(*) as 주문수
	 , avg(count(*)) over() as 전체회원의주문수평균
  from orders s
 group by s.customer_id