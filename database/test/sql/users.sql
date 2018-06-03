--
-- Test of 2 user roles: app and admin
--

-- Suppress NOTICE messages when users/groups don't exist
set client_min_messages to 'warning';

-- Clean up in case a prior test run failed
drop table if exists test;

-- viewpoint from admin user, it:
set session authorization admin;

-- should not be able to drop public schema
drop schema public;

-- should be able to create a new table
create table test (
  col integer
);
