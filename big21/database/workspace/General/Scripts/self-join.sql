create table emp_self (
	  id			integer			-- 사원번호
	, name			varchar(30)		-- 사원명
	, manager_id	integer			-- 상사의 사원번호
);

select * from emp_self;

insert into emp_self(id, name) values(10, '홍길동');
insert into emp_self values(20, '고길동', 10);
insert into emp_self values(30, '마이콜', 20);
insert into emp_self values(40, '희동이', 20);

-- 요건 : 사원 번호, 사원명, 상사의 사원명
-- self join
select e1.id, e1.name, e2.name
  from emp_self e1
  left join emp_self e2 on e1.manager_id = e2.id
;


-- cross join
select *
  from emp as e
  cross join depart as d 
;