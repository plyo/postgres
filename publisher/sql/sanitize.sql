CREATE OR REPLACE FUNCTION sanitize_email(_t VARCHAR, _c VARCHAR)
  RETURNS VOID AS
$$
BEGIN
  EXECUTE format('UPDATE "%s" SET "%s" = RIGHT(md5("%s"), 12) || SUBSTRING("%s", ''@.+$'');', _t, _c, _c, _c);
END
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sanitize_phone(_t VARCHAR, _c VARCHAR)
  RETURNS VOID AS
$$
BEGIN
  EXECUTE format('UPDATE "%s" SET "%s" = ''93000000'' WHERE "%s" IS NOT NULL;', _t, _c, _c);
END
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sanitize_value(_t VARCHAR, _c VARCHAR)
  RETURNS VOID AS
$$
BEGIN
  EXECUTE format('UPDATE "%s" SET "%s" = RIGHT(md5("%s"), 12);', _t, _c, _c);
END
$$
LANGUAGE plpgsql;

SELECT sanitize_email('emails' :: VARCHAR, 'email' :: VARCHAR);
SELECT sanitize_email('emails' :: VARCHAR, 'recipientEmail' :: VARCHAR);
SELECT sanitize_email('users' :: VARCHAR, 'email' :: VARCHAR);
SELECT sanitize_email('contacts' :: VARCHAR, 'email' :: VARCHAR);
SELECT sanitize_email('contacts' :: VARCHAR, 'fromEmail' :: VARCHAR);
SELECT sanitize_email('members' :: VARCHAR, 'email' :: VARCHAR);

SELECT sanitize_phone('emails' :: VARCHAR, 'phone' :: VARCHAR);
SELECT sanitize_phone('users' :: VARCHAR, 'phone' :: VARCHAR);
SELECT sanitize_phone('contacts' :: VARCHAR, 'phone' :: VARCHAR);

SELECT sanitize_value('emails' :: VARCHAR, 'name' :: VARCHAR);
SELECT sanitize_value('users' :: VARCHAR, 'displayName' :: VARCHAR);
SELECT sanitize_value('contacts' :: VARCHAR, 'name' :: VARCHAR);
SELECT sanitize_value('members' :: VARCHAR, 'firstName' :: VARCHAR);
SELECT sanitize_value('members' :: VARCHAR, 'lastName' :: VARCHAR);

DROP FUNCTION sanitize_email(_t VARCHAR, _c VARCHAR );
DROP FUNCTION sanitize_phone(_t VARCHAR, _c VARCHAR );
DROP FUNCTION sanitize_value(_t VARCHAR, _c VARCHAR );
