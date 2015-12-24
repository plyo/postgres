#!/usr/bin/env bash

echo "Saving password for postgres"
echo "db:5432:*:postgres:$POSTGRES_PASS" > /root/.pgpass
chmod 0600 /root/.pgpass

echo "Prepare google API credentials"
jq "setpath([\"client_id\"]; \"$CLIENT_ID\") | setpath([\"client_secret\"]; \"$CLIENT_SECRET\")" \
  google_api_credentials.template.json > google_api_credentials.json
cat google_api_credentials.json

echo "Prepare google OAUTH credentials"
jq "setpath([\"access_token\"]; \"$ACCESS_TOKEN\") | setpath([\"refresh_token\"]; \"$REFRESH_TOKEN\") | setpath([\"expiry_date\"]; \"$EXPIRY_DATE\") " \
  google_oauth_credentials.template.json > google_oauth_credentials.json
cat google_oauth_credentials.json

echo "Starting cron with following rules:"
cat /etc/cron.d/crontab
cron
tail -f /var/log/cron.log
