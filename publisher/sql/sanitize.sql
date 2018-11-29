
-- we define sanitization functions first:
-- - sanitize_email
-- - sanitize_phone
-- - sanitize_value
create or replace function sanitize_email(_t varchar, _c varchar)
  returns void as
$$
declare
  affected numeric;
begin
  execute format('update "%s" set "%s" = right(md5("%s"), 12) || substring("%s", ''@.+$'');', _t, _c, _c, _c);
  get diagnostics affected = row_count;
  raise notice '%.% is sanitized: % rows affected', _t, _c, affected;
end
$$
language plpgsql;

create or replace function sanitize_phone(_t varchar, _c varchar)
  returns void as
$$
declare
  affected numeric;
begin
  execute format('update "%s" set "%s" = ''93000000'' where "%s" is not null;', _t, _c, _c);
  get diagnostics affected = row_count;
  raise notice '%.% is sanitized: % rows affected', _t, _c, affected;
end
$$
language plpgsql;

create or replace function sanitize_value(_t varchar, _c varchar)
  returns void as
$$
declare
  affected numeric;
begin
  execute format('update "%s" set "%s" = right(md5("%s"), 12);', _t, _c, _c);
  get diagnostics affected = row_count;
  raise notice '%.% is sanitized: % rows affected', _t, _c, affected;
end
$$
language plpgsql;

-- this query is for demo purposes only. it shows all the columns with non-null comments.
-- the query is a base for filtering columns to sanitize.
select
  c.table_name,
  c.column_name,
  pgd.description
from pg_catalog.pg_statio_all_tables as st
  inner join pg_catalog.pg_description pgd on (pgd.objoid = st.relid)
  inner join information_schema.columns c on (pgd.objsubid = c.ordinal_position
                                              and c.table_schema = st.schemaname and c.table_name = st.relname);

-- call sanitize_email on every column containing sanitize_as_email in the comment
select sanitize_email(res.table_name :: varchar, res.column_name :: varchar)
from (select
        c.table_name,
        c.column_name
      from pg_catalog.pg_statio_all_tables as st
        inner join pg_catalog.pg_description pgd on (pgd.objoid = st.relid)
        inner join information_schema.columns c on (pgd.objsubid = c.ordinal_position
                                                    and c.table_schema = st.schemaname and c.table_name = st.relname)
      where pgd.description like '%SANITIZE_AS_EMAIL%') as res;

-- call sanitize_value on every column containing sanitize_as_value in the comment
select sanitize_value(res.table_name :: varchar, res.column_name :: varchar)
from (select
        c.table_name,
        c.column_name
      from pg_catalog.pg_statio_all_tables as st
        inner join pg_catalog.pg_description pgd on (pgd.objoid = st.relid)
        inner join information_schema.columns c on (pgd.objsubid = c.ordinal_position
                                                    and c.table_schema = st.schemaname and c.table_name = st.relname)
      where pgd.description like '%SANITIZE_AS_VALUE%') as res;

-- call sanitize_phone on every column containing sanitize_as_phone in the comment
select sanitize_phone(res.table_name :: varchar, res.column_name :: varchar)
from (select
        c.table_name,
        c.column_name
      from pg_catalog.pg_statio_all_tables as st
        inner join pg_catalog.pg_description pgd on (pgd.objoid = st.relid)
        inner join information_schema.columns c on (pgd.objsubid = c.ordinal_position
                                                    and c.table_schema = st.schemaname and c.table_name = st.relname)
      where pgd.description like '%SANITIZE_AS_PHONE%') as res;

-- cleanup the functions
drop function sanitize_email(_t varchar, _c varchar );
drop function sanitize_phone(_t varchar, _c varchar );
drop function sanitize_value(_t varchar, _c varchar );
