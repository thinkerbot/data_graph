-- Describes everything needed to create the database schema.

create table depts (
  id    integer primary key,
  name  text,
  city  text,
  state text
);

create table jobs (
  id   integer primary key,
  name text
);

create table emps (
  id         integer primary key,
  first_name text,
  last_name  text,
  job_id     number(15),
  dept_id    number(15),
  manager_id number(15),
  salary     number(7)
);

create table products (
  id   integer,
  name varchar2(50),
  primary key(id)
);

create table tariffs (
  tariff_id  integer,
  start_date text,
  amount     integer,
  primary key(tariff_id, start_date)
);

create table product_tariffs (
  product_id        integer,
  tariff_id         integer,
  tariff_start_date text,
  primary key(product_id, tariff_id, tariff_start_date),
  foreign key(product_id) references products(id),
  foreign key(tariff_id, tariff_start_date) references tariffs(tariff_id, start_date)
);
