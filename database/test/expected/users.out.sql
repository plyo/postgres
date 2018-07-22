--
-- Test of 2 user roles: app and admin
--
-- Suppress NOTICE messages when users/groups don't exist
set client_min_messages to 'warning';
SET
-- Clean up in case a prior test run failed
drop table if exists users_test;
DROP TABLE
drop table if exists users_test_2;
DROP TABLE
-------------------------------
-- viewpoint from admin user --
-------------------------------
set session authorization admin;
SET
set search_path to test_schema;
SET
-- admin user:
--------------
-- should not be able to drop the schema
drop schema test_schema;
psql:test/sql/users.sql:22: ERROR:  must be owner of schema test_schema
-- should be able to create a new table
create table users_test (
  col integer
);
CREATE TABLE
-- should be able to create a new table in private schema
create table test_schema_private.users_test_private (
  col integer
);
CREATE TABLE
-- should be able to use DML
insert into users_test (col) values (1);
INSERT 0 1
update users_test set col = 2 where col = 1;
UPDATE 1
select * from users_test;
 col 
-----
   2
(1 row)

delete from users_test;
DELETE 1
-----------------------------
-- viewpoint from app user --
-----------------------------
set session authorization app;
SET
-- app user:
--------------
-- should not be able to drop the schema
drop schema test_schema;
psql:test/sql/users.sql:49: ERROR:  must be owner of schema test_schema
-- should not be able to create a new table
create table users_test_2 (
  col integer
);
psql:test/sql/users.sql:54: ERROR:  permission denied for schema test_schema
LINE 1: create table users_test_2 (
                     ^
-- should not be able to remove existent one
drop table users_test;
psql:test/sql/users.sql:57: ERROR:  must be owner of relation users_test
-- should not be able to alter existent table
alter table users_test
  add column col2 integer;
psql:test/sql/users.sql:61: ERROR:  must be owner of relation users_test
-- should not be able to create a new table in private schema
create table test_schema_private.users_test_private_2 (
  col integer
);
psql:test/sql/users.sql:66: ERROR:  permission denied for schema test_schema_private
LINE 1: create table test_schema_private.users_test_private_2 (
                     ^
-- should not be able to use DML with private schema
insert into test_schema_private.users_test_private (col) values (1);
psql:test/sql/users.sql:69: ERROR:  permission denied for schema test_schema_private
LINE 1: insert into test_schema_private.users_test_private (col) val...
                    ^
update test_schema_private.users_test_private set col = 2 where col = 1;
psql:test/sql/users.sql:70: ERROR:  permission denied for schema test_schema_private
LINE 1: update test_schema_private.users_test_private set col = 2 wh...
               ^
select * from test_schema_private.users_test_private;
psql:test/sql/users.sql:71: ERROR:  permission denied for schema test_schema_private
LINE 1: select * from test_schema_private.users_test_private;
                      ^
delete from test_schema_private.users_test_private;
psql:test/sql/users.sql:72: ERROR:  permission denied for schema test_schema_private
LINE 1: delete from test_schema_private.users_test_private;
                    ^
-- should be able to use DML
insert into users_test (col) values (1);
INSERT 0 1
update users_test set col = 2 where col = 1;
UPDATE 1
select * from users_test;
 col 
-----
   2
(1 row)

delete from users_test;
DELETE 1
-------------
-- cleanup --
-------------
reset session authorization;
RESET
drop table users_test;
DROP TABLE
drop table test_schema_private.users_test_private;
DROP TABLE
