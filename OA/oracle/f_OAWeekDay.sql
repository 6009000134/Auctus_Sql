create or replace function f_OAWeekDay(v_date in date)
return int
is
       v_num int;
begin
  select case when to_char(v_date,'d')='1'  then 6
   when to_char(v_date,'d')='2' then 0
     when to_char(v_date,'d')='3'  then 1
       when to_char(v_date,'d')='4'  then 2
         when to_char(v_date,'d')='5'  then 3
           when to_char(v_date,'d')='6'  then 4
                       when to_char(v_date,'d')='7'  then 5
                        else 999 end into v_num  from dual;
       return v_num;
end;
