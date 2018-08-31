--
-- Test of 2 user roles: app and admin
--

-- Suppress NOTICE messages when users/groups don't exist
set client_min_messages to 'warning';

-- Clean up in case a prior test run failed
drop table if exists users_test;
drop table if exists users_test_2;

-------------------------------
-- viewpoint from admin user --
-------------------------------
set session authorization admin;
set search_path to test_schema;

-- admin user:
--------------

-- should not be able to drop the schema
drop schema test_schema;

-- should be able to create a new table
create table users_test (
  col integer
);

-- should be able to create a new table in private schema
create table test_schema_private.users_test_private (
  col integer
);

-- should be able to use DML
insert into users_test (col) values (1);
update users_test set col = 2 where col = 1;
select * from users_test;
delete from users_test;

-- should be able to create a role
create role test_role;

-----------------------------
-- viewpoint from app user --
-----------------------------
set session authorization app;

-- app user:
--------------

-- should not be able to drop the schema
drop schema test_schema;

-- should not be able to create a new table
create table users_test_2 (
  col integer
);

-- should not be able to remove existent one
drop table users_test;

-- should not be able to alter existent table
alter table users_test
  add column col2 integer;

-- should not be able to create a new table in private schema
create table test_schema_private.users_test_private_2 (
  col integer
);

-- should not be able to use DML with private schema
insert into test_schema_private.users_test_private (col) values (1);
update test_schema_private.users_test_private set col = 2 where col = 1;
select * from test_schema_private.users_test_private;
delete from test_schema_private.users_test_private;

-- should be able to use DML
insert into users_test (col) values (1);
update users_test set col = 2 where col = 1;
select * from users_test;
delete from users_test;

-- should not be able to create a role
create role test_role_1;

-- should have pgcrypto extension installed
select count(*)
from pg_extension
where extname = 'pgcrypto';

-- should have ltree extension installed
select count(*)
from pg_extension
where extname = 'ltree';

-------------
-- cleanup --
-------------

reset session authorization;
drop table users_test;
drop table test_schema_private.users_test_private;
drop role test_role;
