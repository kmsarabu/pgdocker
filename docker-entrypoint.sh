#!/bin/bash

eval '${PGHOME}/bin/initdb --pgdata=${PGDATA} --wal-segsize=256 --username=postgres --pwfile=<(echo "$pgpassword") -E utf8 --auth-host=md5'
echo 'host    all             all             0.0.0.0/0                 md5' >> /pgdata/db1/pg_hba.conf
egrep -v '^listen_address' /pgdata/db1/postgresql.conf > t.tmp
mv t.tmp /pgdata/db1/postgresql.conf && rm -f t.tmp
echo "listen_addresses = '*'" >> /pgdata/db1/postgresql.conf
unset pgpassword
echo 'PostgreSQL init process complete; ready for start up.'
exec "$@"
