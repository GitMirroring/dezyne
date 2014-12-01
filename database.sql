create table users (name varchar, email varchar, cred varchar(64), salt varchar(64));
create table events(time timestamp with time zone, command varchar(128), direction varchar(64), sha1 varchar(40), FOREIGN KEY(sha1) REFERENCES files(sha1));
create table files(sha1 varchar(40) PRIMARY KEY, content text);
