FROM postgres:17.0
COPY dump_fbi_17_11_24.sql /docker-entrypoint-initdb.d/dump_fbi_17_11_24.sql

COPY init-db.sh /init-db.sh
