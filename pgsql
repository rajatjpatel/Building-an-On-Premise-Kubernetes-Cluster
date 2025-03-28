sudo apt-get remove postgresql*
sudo apt install curl ca-certificates
sudo install -d /usr/share/postgresql-common/pgdg
sudo curl -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc --fail https://www.postgresql.org/media/keys/ACCC4CF8.asc
sudo sh -c 'echo "deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
sudo apt update
sudo apt -y install postgresql
systemctl status postgresql && systemctl restart postgresql
nano /etc/postgresql/14/main/postgresql.conf
listen_addresses='*'
systemctl restart postgresql
ss -antpl | grep 5432
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

nano /etc/postgresql/14/main/pg_hba.conf  ##in the case we need to access from out this server then only we will add the following line
local   all             all                                     trust

