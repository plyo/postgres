UPDATE emails
SET
  email = regexp_replace(email, '(^[^@]+)', md5(email)),
  name  = md5(name);
