--
-- Test of 2 user roles: app and admin
--
-- Suppress NOTICE messages when users/groups don't exist
set client_min_messages to 'warning';
SET
-- Clean up in case a prior test run failed
drop table if exists test;
DROP TABLE
-- viewpoint from admin user, it:
set session authorization admin;
SET
-- should not be able to drop public schema
drop schema public;
psql:test/sql/users.sql:15: ERROR:  must be owner of schema public
-- should be able to create a new table
create table test (
  col integer
);
CREATE TABLE
