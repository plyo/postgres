
create schema sanitizing;

-- we define sanitization functions first:
-- - sanitize_email
-- - sanitize_phone
-- - sanitize_value
-- - sanitize_nullable
-- - sanitize_jsonb
create or replace function sanitizing.sanitize_email(_t varchar, _c varchar)
  returns void as
$$
declare
  affected numeric;
begin
  execute format(
    'with data as (
      select
        id,
        string_agg(
          right(md5(e), 8) || substring(e, ''@.+$'') || ''t'',
          '',''
          ) as sanitized
      from %1$I, unnest(regexp_split_to_array(%2$I, '','')) e
      group by id
    )
    update %1$I
    set %2$I = case when sanitized isnull then ''emailNotValid@plyo.io'' else sanitized end
    from data
    where data.id = %1$I.id;', _t, _c);
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
  execute format('update %1$I set %2$I = ''93000000'' where %2$I is not null;', _t, _c);
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
  execute format('update %1$I set %2$I = right(md5(%2$I), 12);', _t, _c);
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
  execute format('update %I set %I = null;', _t, _c);
  get diagnostics affected = row_count;
  raise notice '%.% is sanitized: % rows affected', _t, _c, affected;
end
$$
language plpgsql;

create or replace function sanitizing.sanitize_as_empty_jsonb(_t varchar, _c varchar)
  returns void as
$$
declare
  affected numeric;
begin
  execute format('update %I set %I = ''{}''::jsonb;', _t, _c);
  get diagnostics affected = row_count;
  raise notice '%.% is sanitized: % rows affected', _t, _c, affected;
end
$$
language plpgsql;

create or replace function sanitizing.get_sanitized_jsonb(obj jsonb)
  returns jsonb as
$$
declare
  key_ text;
begin
  for key_ in select k from jsonb_object_keys(obj) as t(k) loop
      if jsonb_typeof(obj -> key_) = 'string' then
        if obj ->> key_ ~ '.+@.+\..+' then
          obj = jsonb_set(
            obj,
            array[key_],
            to_jsonb((
              select string_agg(right(md5(e), 8) || substring(e, '@.+$') || 't',',')
              from unnest(regexp_split_to_array(obj ->> key_, ',')) e
            ))
          );
        elseif obj ->> key_ ~ '[0-9]' and obj ->> key_ !~ '[A-Za-z]' then
          obj = jsonb_set(obj, array[key_], to_jsonb(93000000));
        elseif obj ->> key_ ~ '\s' then
          obj = jsonb_set(obj, array[key_], to_jsonb(right(md5(obj ->> key_), 12)));
        end if;
      elseif jsonb_typeof(obj -> key_) = 'object' then
        obj = jsonb_set(obj, array[key_], sanitizing.get_sanitized_jsonb(obj -> key_) );
      end if;
    end loop;
  return obj;
end
$$
  language plpgsql;

create or replace function sanitizing.sanitize_jsonb(_t varchar, _c varchar)
  returns void as
$$
declare
  affected numeric;
begin
  execute format('update %I set %I = sanitizing.get_sanitized_jsonb(%I);', _t, _c, _c);
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

-- truncate table which are not needed for the development before the sanitizing (logs, emails etc);
-- a table must have 'TRUNCATE_ON_SANITIZE' comment
do $$
  declare t text;
  begin
    for t in select relname from pg_class
             where relkind = 'r' and obj_description(oid) = 'TRUNCATE_ON_SANITIZE' loop
        execute 'truncate table ' || quote_ident(t) || ' cascade'; -- cascade to drop formDataImages etc
      end loop;
  end
$$;

-- call sanitize_email on every column containing SANITIZE_AS_EMAIL in the comment
select sanitizing.sanitize_email(res.table_name :: varchar, res.column_name :: varchar)
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

-- call sanitize_as_empty_jsonb on every column containing SANITIZE_AS_EMPTY_JSONB in the comment
select sanitizing.sanitize_as_empty_jsonb(res.table_name :: varchar, res.column_name :: varchar)
from (select
        c.table_name,
        c.column_name
      from pg_catalog.pg_statio_all_tables as st
        inner join pg_catalog.pg_description pgd on (pgd.objoid = st.relid)
        inner join information_schema.columns c on (pgd.objsubid = c.ordinal_position
                                                    and c.table_schema = st.schemaname and c.table_name = st.relname)
      where pgd.description ilike '%SANITIZE_AS_EMPTY_JSONB%') as res;

-- cleanup the functions
drop schema sanitizing cascade;
