
create schema sanitizing;

-- we define sanitization functions first:
-- - sanitize_email
-- - sanitize_phone
-- - sanitize_value
-- - sanitize_nullable
-- - sanitize_jsonb
create or replace function sanitizing.sanitize_emails_in_string(_s varchar)
  returns varchar AS
$$
declare
begin
  return string_agg(
      case word like '%@%'
      when true
        then right(md5(word), 12) || substring(word, '@.+$')
      else word
      end,
      ''
  )
  from unnest(regexp_split_to_array(
  _s,
  '((?=\m[[:alnum:]]*?@[[:alnum:]]*?\.[[:alnum:]]*?\M)|(?<=\m[[:alnum:]]*?@[[:alnum:]]*?\.[[:alnum:]]*?\M))'
  )) word
  group by true;
end
$$
language plpgsql;

create or replace function sanitizing.sanitize_emails(_t varchar, _c varchar)
  returns void as
$$
declare
  affected numeric;
begin
  execute format('update "%s" set "%s" = sanitize_emails_in_string("%s");', _t, _c, _c);
  get diagnostics affected = row_count;
  raise notice '%.% is sanitized: % rows affected', _t, _c, affected;
end
$$
language plpgsql;

create or replace function sanitizing.sanitize_phone(_t varchar, _c varchar)
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

create or replace function sanitizing.sanitize_value(_t varchar, _c varchar)
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

create or replace function sanitizing.sanitize_nullable(_t varchar, _c varchar)
  returns void as
$$
declare
  affected numeric;
begin
  execute format('update "%s" set "%s" = NULL;', _t, _c, _c);
  get diagnostics affected = row_count;
  raise notice '%.% is sanitized: % rows affected', _t, _c, affected;
end
$$
language plpgsql;

create or replace function sanitizing.sanitize_jsonb(_t varchar, _c varchar)
  returns void as
$$
declare
  affected numeric;
begin
  execute format('update "%s" set "%s" = ''{}''::jsonb;', _t, _c, _c);
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

-- call sanitize_emails on every column containing SANITIZE_AS_EMAIL in the comment
select sanitizing.sanitize_emails(res.table_name :: varchar, res.column_name :: varchar)
from (select
        c.table_name,
        c.column_name
      from pg_catalog.pg_statio_all_tables as st
        inner join pg_catalog.pg_description pgd on (pgd.objoid = st.relid)
        inner join information_schema.columns c on (pgd.objsubid = c.ordinal_position
                                                    and c.table_schema = st.schemaname and c.table_name = st.relname)
      where pgd.description ilike '%SANITIZE_AS_EMAIL%') as res;

-- call sanitize_value on every column containing SANITIZE_AS_VALUE in the comment
select sanitizing.sanitize_value(res.table_name :: varchar, res.column_name :: varchar)
from (select
        c.table_name,
        c.column_name
      from pg_catalog.pg_statio_all_tables as st
        inner join pg_catalog.pg_description pgd on (pgd.objoid = st.relid)
        inner join information_schema.columns c on (pgd.objsubid = c.ordinal_position
                                                    and c.table_schema = st.schemaname and c.table_name = st.relname)
      where pgd.description ilike '%SANITIZE_AS_VALUE%') as res;

-- call sanitize_phone on every column containing SANITIZE_AS_PHONE in the comment
select sanitizing.sanitize_phone(res.table_name :: varchar, res.column_name :: varchar)
from (select
        c.table_name,
        c.column_name
      from pg_catalog.pg_statio_all_tables as st
        inner join pg_catalog.pg_description pgd on (pgd.objoid = st.relid)
        inner join information_schema.columns c on (pgd.objsubid = c.ordinal_position
                                                    and c.table_schema = st.schemaname and c.table_name = st.relname)
      where pgd.description ilike '%SANITIZE_AS_PHONE%') as res;

-- call sanitize_nullable on every column containing SANITIZE_AS_NULLABLE in the comment
select sanitizing.sanitize_nullable(res.table_name :: varchar, res.column_name :: varchar)
from (select
        c.table_name,
        c.column_name
      from pg_catalog.pg_statio_all_tables as st
        inner join pg_catalog.pg_description pgd on (pgd.objoid = st.relid)
        inner join information_schema.columns c on (pgd.objsubid = c.ordinal_position
                                                    and c.table_schema = st.schemaname and c.table_name = st.relname)
      where pgd.description ilike '%SANITIZE_AS_NULLABLE%') as res;

-- call sanitize_jsonb on every column containing SANITIZE_AS_JSONB in the comment
select sanitizing.sanitize_jsonb(res.table_name :: varchar, res.column_name :: varchar)
from (select
        c.table_name,
        c.column_name
      from pg_catalog.pg_statio_all_tables as st
        inner join pg_catalog.pg_description pgd on (pgd.objoid = st.relid)
        inner join information_schema.columns c on (pgd.objsubid = c.ordinal_position
                                                    and c.table_schema = st.schemaname and c.table_name = st.relname)
      where pgd.description ilike '%SANITIZE_AS_JSONB%') as res;

-- cleanup the functions
drop schema sanitizing cascade;
