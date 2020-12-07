create or replace type t_userrelation as object(
UserID number,
Leader number
);
create or replace type t_userrelation_table as table of t_userrelation;


