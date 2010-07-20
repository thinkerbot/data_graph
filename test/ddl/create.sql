-- Describes everything needed to create the database schema.

create table depts (
  id    integer primary key,
  name  varchar2(20),
  city  varchar2(20),
  state varchar2(2)
);

create table jobs (
  id   integer primary key,
  name varchar2(20)
);

create table emps (
  id         integer primary key,
  first_name varchar2(15),
  last_name  varchar2(15),
  job_id     number(15),
  dept_id    number(15),
  manager_id number(15),
  salary     number(7)
);
