#!/bin/bash

#change the password
service postgresql start >/dev/null 2>&1
if [ ! -f /.postgres_pass_modified ]; then
	/modify_postgres_pass.sh
fi
/create_plyo.sh
service postgresql stop >/dev/null 2>&1

#start PostgreSQL 
su - postgres -c "/usr/lib/postgresql/9.4/bin/postgres -D /var/lib/postgresql/9.4/main -c config_file=/etc/postgresql/9.4/main/postgresql.conf"
