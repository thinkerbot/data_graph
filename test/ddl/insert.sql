-- Describes shared fixture (ie not test-specific) data.

insert into depts values (1, 'Accounting', 'New York', 'NY');
insert into depts values (2, 'Research',   'Dallas',   'TX');
insert into depts values (3, 'Sales',      'Chicago',  'IL');
insert into depts values (4, 'Operations', 'Boston',   'MA');

insert into jobs values (1, 'President');
insert into jobs values (2, 'Manager');
insert into jobs values (3, 'Analyst');
insert into jobs values (4, 'Clerk');
insert into jobs values (5, 'Salesman');

insert into emps values (1,  'Kim',      'King',   1, 1, null, 5000);
insert into emps values (2,  'Jim',      'Jones',  2, 2, 1,    2975);
insert into emps values (3,  'Fred',     'Ford',   3, 2, 2,    3000);
insert into emps values (4,  'Sally',    'Smith',  4, 2, 3,    800);
insert into emps values (5,  'Bill',     'Blake',  2, 3, 1,    2850);
insert into emps values (6,  'Amy',      'Allen',  5, 3, 5,    1600);
insert into emps values (7,  'William',  'Ward',   5, 3, 5,    1250);
insert into emps values (8,  'Mike',     'Martin', 5, 3, 5,    1250);
insert into emps values (9,  'Carla',    'Clark',  2, 1, 1,    2450);
insert into emps values (10, 'Sam',      'Scott',  3, 2, 2,    3000);
insert into emps values (11, 'Tom',      'Turner', 5, 3, 5,    1500);
insert into emps values (12, 'Abe',      'Adams',  4, 2, 10,   1100);
insert into emps values (13, 'Joan',     'James',  4, 3, 5,    950);
insert into emps values (14, 'Michelle', 'Miller', 4, 1, 9,    1300);

insert into products values (1, 'Product One');
insert into products values (2, 'Product Two');

insert into tariffs values (1, date('2010-09-08'), 50);
insert into tariffs values (2, date('2010-09-08'), 0);
insert into tariffs values (1, date('2010-09-09'), 100);

insert into product_tariffs values (1, 1, date('2010-09-08'));
insert into product_tariffs values (1, 2, date('2010-09-08'));
insert into product_tariffs values (2, 2, date('2010-09-08'));
