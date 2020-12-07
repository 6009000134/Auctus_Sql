
declare v_number number:=10;

begin
  
  DBMS_OUTPUT.PUT_LINE(v_number);
  
  while v_number<12 loop
  DBMS_OUTPUT.PUT_LINE(v_number);
  v_number:=v_number+1    ;
    end loop;
  
  begin
  DBMS_OUTPUT.PUT_LINE(v_number);
  end ;
  
end ;


declare rs strToTable:= strToTable();

begin
    declare str varchar(100):='123,1234,12345';
    begin      
     while nvl(instr(str,','),0)>0 loop 
      rs.extend;
      rs(rs.count):=substr(str,1,instr(str,',')-1);
      str:=substr(str,instr(str,',')+1); 
      end loop;
         rs.extend;
             rs(rs.count):=str;    
begin
              dbms_output.put_line(rs(1));
  end ;
     end ;

 end;
 
declare  
type my_table is table of hrmresource%rowtype
index by binary_integer;
new_table my_table;
v_num number:=0;
 cursor cut_test is select id,lastname from hrmresource;
 begin
   for v_hr in cut_test loop
     v_num:=v_num+1;
     select * into new_table(new_table) from hrmresource
where lastname=v_hr.lastname;
     dbms_output.put_line(v_hr.lastname);
         dbms_output.put_line(to_char(v_num)||'------------'||new_table(1).lastname);          
   end loop;        
 end ;



declare v_test t_auctustest_table:=t_auctustest_table();
begin
  select t_auctustest(a.id,a.id) bulk collect into v_test from hrmresource a inner join hrmdepartmentdefined b on a.departmentid=b.deptid;
     dbms_output.put_line(v_test(1).userid);
end ;

select * from table(f_userrelate())

select * from v_auctus_attendancedata_new


select a.userid,a.lastname,a.signdate,b.signtime
,case when to_char(nvl(d.LASTNAME,''))=to_char('蔡东志') then '' else d.lastname end  Leader
,case when to_char(nvl(d.LASTNAME,''))=to_char('蔡东志') then '' else d.email end  LeaderMail
,'蔡东志' CEO
,(select email from hrmresource where lastname='蔡东志') CEOMail
from v_auctus_hrmdate a 
left join HrmScheduleSign b on a.userid=b.userid and a.signdate=b.signdate
left join table(f_userrelate()) c on a.userid=c.userid left join hrmresource d on c.leader=d.id
where a.signdate in ('2020-06-24','2020-06-25')
order by c.leader,a.lastname,a.signdate


select t.*,t1.leader
,case when to_char(nvl(t2.LASTNAME,''))=to_char('蔡东志') then '' else t2.lastname end  Leader
,case when to_char(nvl(t2.LASTNAME,''))=to_char('蔡东志') then '' else t2.email end  "LeaderMail"
,'蔡东志' CEO
,(select email from hrmresource where lastname='蔡东志') CEOMail
from (
select a.userid,a.subcompanyid1,a.lastname,a.departmentid,a.signdate,min(b.signtime)MinTime,max(b.signtime)MaxTime--每人打卡情况
from v_auctus_hrmdate a 
left join HrmScheduleSign b on a.userid=b.userid and a.signdate=b.signdate
where a.status=1
group by a.userid,a.subcompanyid1,a.departmentid,a.signdate,a.lastname
) t left join table(f_userrelate())  t1 on t.userid=t1.userid left join hrmresource t2 on t1.leader=t2.id
where t.signdate in ('2020-07-29','2020-07-28')
order by t2.id





