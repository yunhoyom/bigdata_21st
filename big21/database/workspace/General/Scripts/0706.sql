-- 트리거
select * from customers c limit 1;

-- 트리거 문법 정리
-- create trigger 트리거명
-- {before|after|instead of} {insert | update | delete | truncate}
-- on 테이블명
-- [for each {row | statement}]
-- [when (condition)]
-- execute function 함수명();

-- before|after|instead of
-- before : 실제 작업 전 해당 트리거 실행, 값 검증/수정, 취소 가능
-- after : 실제 작업 후 해당 트리거 실행, 로그 기록에 많이 사용. 연관 작업 등에 적합.
-- instead of : view에 대해서만 사용 가능. 실제 작업 대신 트리거 로직 실행할 때 사용.

-- 실행 단위
-- for each row : 영향받은 행마다 한 번씩 실행. new/old 사용 가능(예. delete로 10행이 영향 받으면 한 번씩 실행.)
-- for each statement : 문장당 한 번만 실행(기본값.), new/old 사용 불가

-- 이벤트(사건)
-- insert, update, delete, truncate
-- or 붙여서 여러 개 지정 가능 : insert or update
-- 특정 컬럼 지정 가능: update of column1, column2 처럼 특정 컬럼 변경 시에만 트리거 발동하도록 제한 가능

-- 요건 : 주문이 들어오거나, 수정되거나, 삭제되는 로그를 저장하는 트리거
-- 주문 정보를 기록하는 테이블
create table audit(
	table_name	varchar(100),	-- 변경 작업이 발생한 테이블
	action		varchar(30),	-- insert, update, delete
	old_data	varchar(500),	-- 이전 데이터 : action 전 데이터
	new_data	varchar(500),	-- 이후 데이터 : action 후 데이터
	changed_at	timestamp		-- 변경 시간
); 

-- 함수 : 기록(insert)하는 함수
create function audit_log() returns trigger as $$
begin
	insert into audit (table_name, action, old_data, new_data, changed_at)
	values(tg_table_name, tg_op, row_to_json(OLD), row_to_json(NEW), now()); -- postgres 지정
	return coalesce(new, old); -- coalesce: NULL 아닌 것 반환
end;
$$ language plpgsql;

create trigger trg_audit
after insert or update or delete on orders
for each row
execute function audit_log();

-- drop trigger trg_audit on orders;

select * from orders limit 3;

select distinct status from orders
;

-- 11233	3851	2024-12-14 11:52:05.374	배송완료	6687680.00	김해
-- 11233 => 환불 변경
update orders
   set status = '환불'
 where order_id = 11233
;

select * from audit;

-- 데이터 검증
-- 상품 추가되거나 수정(update)될 때 새로운 가격 음수 처리 방지
-- products table : price column > 0
-- 1단계 : trigger로 처리할 함수 정의
create function check_positive_price() returns trigger as $$
begin
	if NEW.price < 0 then 
		raise exception 'price는 음수가 될 수 없습니다.: %', NEW.price;
	end if;
	return NEW;
end;
$$ language plpgsql;

-- 2단계 : trigger 선언
create trigger trg_check_price
before insert or update on products
for each row
execute function check_positive_price();

-- 2(product_id)	6	모던 버전 2	110750.00	251	판매중	2024-02-03 00:00:00.000
select * from products limit 1;

update products p
   set price = -1000
 where p.product_id = 2
;
