apt-get remove --purge postgresql
apt install gnupg gnupg2 gnupg1 -y
sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
apt-get update -y
apt-get install postgresql-14 -y
In case of diff version 

apt-get -y install postgresql

systemctl status postgresql

Check version
sudo -u postgres psql -c "SELECT version();"

su - postgres
psql

CREATE ROLE root WITH LOGIN SUPERUSER CREATEDB CREATEROLE PASSWORD 'password';
\du

create database trade;
create user dbuser with encrypted password 'nasdaq';
grant all privileges on database trade to nasdaq;
\l
\q
exit

nano /etc/postgresql/14/main/pg_hba.conf

local   all             all                                     trust

nano /etc/postgresql/14/main/postgresql.conf

listen_addresses='*'

systemctl restart postgresql

ss -antpl | grep 5432
