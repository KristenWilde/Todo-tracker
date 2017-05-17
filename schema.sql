create table lists (
  id serial primary key,
  name text not null unique
);

create table todos (
  id serial primary key,
  list_id integer not null references lists(id) on delete cascade,
  name text not null,
  completed boolean not null default false
);