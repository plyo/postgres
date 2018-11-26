UPDATE emails
SET
  email            = regexp_replace(email, '(^[^@]+)', md5(email)),
  "recipientEmail" = regexp_replace("recipientEmail", '(^[^@]+)', md5("recipientEmail")),
  name             = md5(name);

UPDATE emails
SET
  phone = 93000000
WHERE phone IS NOT NULL;

UPDATE users
SET
  email         = regexp_replace(email, '(^[^@]+)', md5(email)),
  "displayName" = md5("displayName");

UPDATE users
SET
  phone = 93000000
WHERE phone IS NOT NULL;

UPDATE contacts
SET
  phone = '93000000'
WHERE phone IS NOT NULL;

UPDATE contacts
SET
  name  = md5(name),
  email = regexp_replace(email, '(^[^@]+)', md5(email)),
  "fromEmail" = regexp_replace("fromEmail", '(^[^@]+)', md5("fromEmail"));

UPDATE members
SET
  "firstName" = RIGHT(md5("firstName"), 20),
  "lastName"  = RIGHT(md5("lastName"), 20),
  email       = RIGHT(regexp_replace(email, '(^[^@]+)', md5(email)), 40);
