
-- We define sanitization functions first:
-- - sanitize_email
-- - sanitize_phone
-- - sanitize_value
CREATE OR REPLACE FUNCTION sanitize_email(_t VARCHAR, _c VARCHAR)
  RETURNS VOID AS
$$
DECLARE
  affected NUMERIC;
BEGIN
  EXECUTE format('UPDATE "%s" SET "%s" = RIGHT(md5("%s"), 12) || SUBSTRING("%s", ''@.+$'');', _t, _c, _c, _c);
  GET DIAGNOSTICS affected = ROW_COUNT;
  RAISE NOTICE '%.% is sanitized: % rows affected', _t, _c, affected;
END
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sanitize_phone(_t VARCHAR, _c VARCHAR)
  RETURNS VOID AS
$$
DECLARE
  affected NUMERIC;
BEGIN
  EXECUTE format('UPDATE "%s" SET "%s" = ''93000000'' WHERE "%s" IS NOT NULL;', _t, _c, _c);
  GET DIAGNOSTICS affected = ROW_COUNT;
  RAISE NOTICE '%.% is sanitized: % rows affected', _t, _c, affected;
END
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sanitize_value(_t VARCHAR, _c VARCHAR)
  RETURNS VOID AS
$$
DECLARE
  affected NUMERIC;
BEGIN
  EXECUTE format('UPDATE "%s" SET "%s" = RIGHT(md5("%s"), 12);', _t, _c, _c);
  GET DIAGNOSTICS affected = ROW_COUNT;
  RAISE NOTICE '%.% is sanitized: % rows affected', _t, _c, affected;
END
$$
LANGUAGE plpgsql;

-- This query is for demo purposes only. It shows all the columns with non-null comments.
-- The query is a base for filtering columns to sanitize.
SELECT
  c.table_name,
  c.column_name,
  pgd.description
FROM pg_catalog.pg_statio_all_tables AS st
  INNER JOIN pg_catalog.pg_description pgd ON (pgd.objoid = st.relid)
  INNER JOIN information_schema.columns c ON (pgd.objsubid = c.ordinal_position
                                              AND c.table_schema = st.schemaname AND c.table_name = st.relname);

-- Call sanitize_email on every column containing SANITIZE_AS_EMAIL in the comment
SELECT sanitize_email(res.table_name :: VARCHAR, res.column_name :: VARCHAR)
FROM (SELECT
        c.table_name,
        c.column_name
      FROM pg_catalog.pg_statio_all_tables AS st
        INNER JOIN pg_catalog.pg_description pgd ON (pgd.objoid = st.relid)
        INNER JOIN information_schema.columns c ON (pgd.objsubid = c.ordinal_position
                                                    AND c.table_schema = st.schemaname AND c.table_name = st.relname)
      WHERE pgd.description LIKE '%SANITIZE_AS_EMAIL%') AS res;

-- Call sanitize_value on every column containing SANITIZE_AS_VALUE in the comment
SELECT sanitize_value(res.table_name :: VARCHAR, res.column_name :: VARCHAR)
FROM (SELECT
        c.table_name,
        c.column_name
      FROM pg_catalog.pg_statio_all_tables AS st
        INNER JOIN pg_catalog.pg_description pgd ON (pgd.objoid = st.relid)
        INNER JOIN information_schema.columns c ON (pgd.objsubid = c.ordinal_position
                                                    AND c.table_schema = st.schemaname AND c.table_name = st.relname)
      WHERE pgd.description LIKE '%SANITIZE_AS_VALUE%') AS res;

-- Call sanitize_phone on every column containing SANITIZE_AS_PHONE in the comment
SELECT sanitize_phone(res.table_name :: VARCHAR, res.column_name :: VARCHAR)
FROM (SELECT
        c.table_name,
        c.column_name
      FROM pg_catalog.pg_statio_all_tables AS st
        INNER JOIN pg_catalog.pg_description pgd ON (pgd.objoid = st.relid)
        INNER JOIN information_schema.columns c ON (pgd.objsubid = c.ordinal_position
                                                    AND c.table_schema = st.schemaname AND c.table_name = st.relname)
      WHERE pgd.description LIKE '%SANITIZE_AS_PHONE%') AS res;

-- Cleanup the functions
DROP FUNCTION sanitize_email(_t VARCHAR, _c VARCHAR );
DROP FUNCTION sanitize_phone(_t VARCHAR, _c VARCHAR );
DROP FUNCTION sanitize_value(_t VARCHAR, _c VARCHAR );
