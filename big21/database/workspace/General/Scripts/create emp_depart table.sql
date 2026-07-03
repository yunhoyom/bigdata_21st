-- 사원 정보 저장 테이블: emp
-- 부서 정보 저장 테이블: depart

create table emp(
	  empid		integer		-- 사원 번호 컬럼
	, empname	varchar(50)	-- 사원 명
	, salary	integer		-- 급여
	, departid	integer		-- 부서 번호
);

 create table depart(
 	  departid		integer			-- 부서 번호
 	, departname	varchar(50)		-- 부서명
 );
 
 --사원 데이터 저장
insert into emp
values (100, '홍길동', 500, 10);

insert into emp
values (101, '고길동', 400, 20);
  
insert into emp
values (102, '마이콜', 300, 20);

insert into emp(empid, empname, salary)
values (103, '희동이', 200);

select * from emp

--부서 데이터 저장
insert into depart 
values(10, '개발팀');

insert into depart
values(20, '총무팀');

insert into depart
values(30, '기획팀');


---------

select * from emp;
select * from depart;


select e.empname
	 , e.salary
	 , d.departname
  from emp e, depart d	-- join 12 row
 where e.departid = d.departid
;

-- 요건
-- 우리 회사 직원의 이름, 급여, 부서명 조회
select 
	   e.empname
	 , e.salary
	 , d.departname
  from emp e, depart d
 where e.departid = d.departid
;

-- ANSI JOIN
select 
	   e.empname
	 , e.salary
	 , d.departname
  from emp e
 inner join depart d			-- 카디시안 곱 조인
    on e.departid = d.departid	-- 조인 조건
;
  
select e.empname
	 , e.salary
	 , d.departname 
  from emp e
  join depart d
    on e.departid = d.departid 
    
-- 요건
-- 사원명, 급여, 부서명 조회 단, 급여 400보다 큰 사원 조회
select e.empname 
	 , e.salary 
	 , d.departname
  from emp e
  join depart d
    on e.departid = d.departid	-- 조인 조건(where로 하면 조인 조건, 일반 조건 같이 들어가 구분 쉽지 x)
 where e.salary >= 400			-- 일반 조건
;

-- 우리 사원 조회 : 사원명, 급여, 부서명 조회
-- 희동이도 출력 left outer join
select e.empname
	 , e.salary
	 , d.departname
  from emp e
  left join depart d
    on e.departid = d.departid 
;


-- 우리 회사 사원과 부서 조회: 사원명, 급여, 부서명 조회
select e.empname
	 , e.salary
	 , d.departname
  from emp e
  full join depart d
    on e.departid = d.departid 
; 