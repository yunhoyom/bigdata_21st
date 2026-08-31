-- 윈도우 함수
-- 기본 구조
--select 컬럼 자리
--	   윈도우 함수(컬럼) over(
--	   	[partition by 분할할 컬럼]	-- 해당 컬럼으로 그루핑. 안 쓰면 전체가 하나로 묶임. cf> group by 
--	   	[order by 정렬할 컬럼]		-- 해당 컬럼으로 정렬. 안 쓰면 진짜 안 쓰는 거.
--	   	[rows | range 프레임 지정]	-- 범위 지정. 아무것도 안 쓰여있으면 기본값 지정
--	   )
--  from 테이블명;

-- over()
-- 원래 select는 한 개 행을 가져와 한 개 행을 생성
-- 예 : 10개 행 => sum => 1개 행으로 압축
-- sum(col) over() : 압축 일어나지 않음
select c.customer_id	-- 회원 번호
	 , count(*)	over()	-- 한 개 row로 압축x.
  from customers c;		-- 50000 row
  

select c.customer_id			-- 회원 번호
	 , count(*)	over(			-- counting
	 	partition by c.grade	-- 등급별로 grouping
	 )
  from customers c;				-- 50000 row
  
-- 주요 윈도우 함수
-- 1. 순위 지정 함수 (Ranking)
-- row_number() : 중복 값과 관계 없이 무조건 순차적인 고유 순위 부여(1,2,3,...)
-- rank() : 중복 값이 있으면 동일 순위 부여, 다음 순위 건너 뜀.(1,2,2,4)
-- dense_rank() : 중복 값이 있으면 동일 순위 부여, 다음 순위 연속하여 부여(1,2,2,3)
  
-- 2. 집계 함수(Aggregate)
-- sum, avg, count, min, max : over()와 조합하여 그룹별 누적합이나 이동 평균 계산 : order by, rows

-- 3. 값 참조 함수(Value)
-- LAG(컬럼, 칸 수) : 현재 행 기준으로 이전 행의 값을 가져옴.(select 문이지만 over로 다른 행을 가져옴.)
-- LEAD(컬럼, 칸 수) : 현재 행 기준으로 다음 행의 값을 가져옴.
-- FIRST_VALUE(컬럼) : 파티션(partition by) / 프레임(row|range) 내의 첫 번째 행 값을 가져옴.
-- LAST_VALUE(컬럼) : 파티션(partition by) / 프레임(row|range) 내의 마지막 행 값을 가져옴.
  
-- 회원당 평균 주문 수
select c."name" 
	 , count(*) as cnt
  from orders o 
  join customers c 
    on o.customer_id = c.customer_id
 group by c.customer_id
 
select s.customer_id
	 , count(*) as 주문수
	 , avg(count(*)) over() as 전체회원의주문수평균
  from orders s
 group by s.customer_id
 
-- 등급별 평균 주문 수
select o.customer_id
	 , count(*) as 회원별주문수
	 , avg(count(*)) over(partition by  ) as 등급별평균주문수
  from orders o 
  join customers c
 group by o.customer_id
 
-- 문제
select *
  from orders o
 order by o.order_date desc
 limit 5
;

select ot.order_date
	 , ot.total_amount
	 , sum(total_amount) over (order by ot.total_amount) as running_total
  from orders_top5 ot
  
-- 카테고리별 매출 비중 및 순위
-- 카테고리명, 카테고리별 매출, 매출 비중, 순위
select c."name"
	 , sum(oi.unit_price * oi.quantity) as 카테고리별매출
	 , sum(oi.unit_price * oi.quantity) / sum(sum(oi.unit_price * oi.quantity)) over () * 100 as 매출비중
	 , rank() over(order by sum(oi.unit_price * oi.quantity) desc)
  from order_items oi
  join products p on oi.product_id = p.product_id
  join categories c on p.category_id = c.category_id
 group by c.category_id
 

-- 고객별 첫 주문 시 가장 많이 선택되는 상품 top 5
-- 취소, 환불 제외
-- 최종 결과: 상품 5개
-- 중간 단계: 고객별 첫 주문 => 상품
 select p."name" , count(*) as cnt
   from (select min(o.order_date) as first_order
	 		  , o.customer_id as customer_id
  		   from orders o
  		  where o.status not in('취소', '환불')
 		  group by o.customer_id
 		)T
   join orders o on T.customer_id = o.customer_id
   join order_items oi on o.order_id = oi.order_id 
   join products p on p.product_id = oi.product_id
  where o.order_date = T.first_order
  group by p."name"
  order by cnt desc
  limit 5
;

-- 다른 방법
-- 1단계. 고객별 첫 주문의 주문번호 조회
-- 2단계. with 문에 넣어서 아래에 select
with first_orders as (
	select t.order_id 
	  from (
			select o.order_id
			     , row_number() over (partition by o.customer_id order by o.order_date asc) as rn
			  from orders o
			 where o.status not in ('취소', '환불')
	  ) t
	 where t.rn=1
)
select p."name"
	 , count(*) as 첫주문건수
  from order_items oi 
  join first_orders fo on oi.order_id = fo.order_id
  join products p on oi.product_id = p.product_id
 group by 1 
 order by 2 desc
 limit 5
;

-- 최종 결과 : 상품 5개
-- 중간 단계 : 고객별 첫 주문 => 상품
-- FIRST_VALUE 사용
with first_orders as (
	select distinct o.customer_id
		 , FIRST_VALUE(o.order_id) over (
		 	partition by o.customer_id
		 	order by o.order_date asc	-- 제일 먼저 주문한 날
		 ) as order_id
	  from orders o
	 where o.status not in ('취소', '환불')
)
select p."name" 
	 , count(*) as 첫주문건수
  from order_items oi
  join first_orders fo on oi.order_id = fo.order_id 
  join products p on oi.product_id = p.product_id
 group by 1
 order by 2 desc
 limit 5
;

-- 누적 매출합, 매출 전월대비(+,-)
-- 월별 매출
with month_tmt as (
	select date_trunc('month', o.order_date)::date as month		-- 월별
	--	 , count(*) as 주문건수
		 , sum(o.total_amount) as tmt
	  from orders o
	 group by 1
	 order by 1 
)
select mt.month, mt.tmt
	 , sum(mt.tmt) over(order by mt."month") as 누적매출	-- 범위 지정 X
	 , mt.tmt - lag(mt.tmt) over(order by mt."month" ) as 전월대비
  from month_tmt mt
 order by mt."month" 
 limit 6
;

-- 범위 지정X
-- default: range betweeen unbounded preceding and current row
-- select sum() over(order by) 
-- 		range betweeen unbounded preceding and current row		-- (between 시작지점 and 끝지점) 
-- range : 현재 행의 값과 같거나 작은 데이터를 가져와라.
-- range 문제점 : 조건을 넘어가는 누적이 있을 수 있다.
--  예. 6/29(10000), 6/30(20000), 7/1(20000), 7/2(30000) 일 때 range를 쓰면 6월 매출에 7/1매출이 들어감.
-- unbounded preceding : 처음부터
-- current row : 현재 행
-- 처음부터 현재까지의 행 중에 현재 행의 값과 같거나 작은 데이터들이 계속 더해져서 누적합이 됨.
-- 현재 행을 가져옴 -> order by 해서 같거나 작은 값들을 모두 더함. 
-- 예. 10000,20000,20000,30000일 때 range의 첫째 행은 10000, 둘째 행이 50000이 됨.(10000,50000,50000,80000)
-- 10000, 30000, 50000, 80000이 되게 하려면 rows 줘야 함.
-- from table;

-- range 쓰임새: 한 달 전부터 오늘까지 데이터 누적 가능 -> 시간과 관련된 범위 지정에는 range가 강력.
-- range between interval '1 month' preceding and current row
-- rows 로는 날짜별로 누적 해결 불가
