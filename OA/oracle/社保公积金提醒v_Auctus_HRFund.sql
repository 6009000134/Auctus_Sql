create or replace view v_Auctus_HRFund
as
select 
h.status,
h.lastname,
h.subcompanyid1,
h.departmentid,
y.subcompanyname,
case when h.subcompanyid1=21 then 55544 
  when h.subcompanyid1=24 then 55543
    when h.subcompanyid1=23 then 55542
      when h.subcompanyid1=22 then 55541
              when h.subcompanyid1=1021 then 55541
else 0 end RolID,
(case when t.supdepid=0 then y.subcompanyname
 when t.supdepid !=0 then (select (select departmentname from hrmdepartment where id = k.supdepid) from hrmdepartment k where k.id =h.departmentid) end)PDepartmentName,
t.departmentname,
h.dismissdate
 from 
hrmresource h
left join hrmdepartment t on t.id =h.departmentid
left join hrmsubcompany y on y.id =h.subcompanyid1
where 1=1 
and h.status =5
and h.dismissdate>to_char(add_months(last_day(sysdate)+15,-2),'yyyy-MM-dd')
and h.dismissdate<to_char(add_months(last_day(sysdate)+16,-1),'yyyy-MM-dd')










