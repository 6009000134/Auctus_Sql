﻿create or replace view v_auctus_hrattendmaildata as
with
data1 as
(
select t."USERID",subcom.subcompanyname,t."LASTNAME",dept.departmentname,t."SIGNDATE",t."MINTIME",t."MAXTIME"
,case when to_char(nvl(t2.LASTNAME,''))=to_char('蔡东志') then '' else t2.lastname end  Leader
,case when to_char(nvl(t2.LASTNAME,''))=to_char('蔡东志') then '' else t2.email end  LeaderMail
,'蔡东志' CEO
,(select email from hrmresource where lastname='蔡东志') CEOMail
from (
select a.userid,a.subcompanyid1,a.lastname,a.departmentid,a.signdate,min(b.signtime)MinTime
,case when a.signdate=to_char(sysdate-1,'yyyy-MM-dd') then max(b.signtime)--每人打卡情况
else '' end MaxTime
from v_auctus_hrmdate a
left join HrmScheduleSign b on a.userid=b.userid and a.signdate=b.signdate
where a.status in (0,1,2,3)
and a.signdate in (to_char(sysdate,'yyyy-MM-dd'),to_char(sysdate-1,'yyyy-MM-dd'))
group by a.userid,a.subcompanyid1,a.departmentid,a.signdate,a.lastname
) t left join (select distinct * from table(f_userrelate()) where leader is not null)  t1 on t.userid=t1.userid left join hrmresource t2 on t1.leader=t2.id
left join hrmdepartment dept on t.departmentid=dept.id
left join hrmsubcompany subcom on subcom.id=t.subcompanyid1
where t.lastname not in ('测试','潘战山')
),--部门数据
data2 as
(
select t."USERID",t."LASTNAME",t."SUBCOMPANYNAME",t."DEPARTMENTNAME",t."SIGNDATE",t."MINTIME",t."MAXTIME",t."LEADER",t."MailNo"
,to_date(t.signdate,'yyyy-MM-dd')+NUMTODSINTERVAL(TO_NUMBER(SUBSTR(t."MINTIME", 1, 2))*60 + TO_NUMBER(SUBSTR(t."MINTIME", 4, 2)),'minute')sbsj
,to_date(t.signdate,'yyyy-MM-dd')+NUMTODSINTERVAL(TO_NUMBER(SUBSTR(t."MAXTIME", 1, 2))*60 + TO_NUMBER(SUBSTR(t."MAXTIME", 4, 2)),'minute')xbsj
,to_date(t.signdate,'yyyy-MM-dd')+NUMTODSINTERVAL(TO_NUMBER(SUBSTR(t1."STARTTIME", 1, 2))*60 + TO_NUMBER(SUBSTR(t1."STARTTIME", 4, 2)),'minute')kq_sbsj
,to_date(t.signdate,'yyyy-MM-dd')+NUMTODSINTERVAL(TO_NUMBER(SUBSTR(t1."ENDTIME", 1, 2))*60 + TO_NUMBER(SUBSTR(t1."ENDTIME", 4, 2)),'minute')kq_xbsj
,to_date(t.signdate,'yyyy-MM-dd')+NUMTODSINTERVAL(TO_NUMBER(SUBSTR(t1."STARTTIME", 1, 2))*60 + TO_NUMBER(SUBSTR(t1."STARTTIME", 4, 2)+to_number(t1."SERIOUSLATEMINUTES")),'minute')kq_txsj

from
(
--蔡总数据
select t."USERID",t.lastname,t.subcompanyname,t.departmentname,t.signdate,t.mintime,t.maxtime,min(t.leader)leader,0 "MailNo"
from data1 t
group by t."USERID",t.lastname,t.subcompanyname,t.departmentname,t.signdate,t.mintime,t.maxtime
union all
--各总监数据
select t."USERID",t.lastname,t.subcompanyname,t.departmentname,t.signdate,t.mintime,t.maxtime,t.leader,m.mailno "MailNo"
from data1 t
inner join
(
select t1.leader,dense_rank() over(partition by t1.ceo order by t1.leader) MailNo
from (
select distinct t.leader,t.ceo,t.LeaderMail
from data1 t
) t1
) m on t.leader=m.leader
)  t  left join v_auctus_kqmanagement t1 on t."USERID"=t1.userid and f_OAWeekDay(to_date(t.signdate,'yyyy-MM-dd'))=to_number(t1.weekday)
),
qj as--请假数据
(
select --a.requestid,b.xm,b.qjlx,b.ksrq,b.kssj,b.jsrq,b.jssj,b.qjsc,b.sy
b.xm,b.qjlx,b.ksrq,b.jsrq
from formtable_main_82 a inner join formtable_main_82_dt1 b on a.id=b.mainid
where (to_char(sysdate,'yyyy-MM-dd') between b.ksrq and b.jsrq or to_char(sysdate-1,'yyyy-MM-dd') between b.ksrq and b.jsrq)
),
waichu as--请假数据
(
select --a.requestid,b.xm,b.qjlx,b.ksrq,b.kssj,b.jsrq,b.jssj,b.qjsc,b.sy
b.detail_resourceid xm,b.detail_fromDate,b.detail_toDate,b.sy
from formtable_main_130 a inner join formtable_main_130_dt1 b on a.id=b.mainid
left join hrmresource c on b.detail_resourceid=c.id
where (to_char(sysdate,'yyyy-MM-dd') between b.detail_fromDate and b.detail_toDate or to_char(sysdate-1,'yyyy-MM-dd') between b.detail_fromDate and b.detail_toDate)
)
select distinct a."USERID",a."LASTNAME",a."SUBCOMPANYNAME",a."DEPARTMENTNAME",a."SIGNDATE",a."MINTIME",a."MAXTIME",a."LEADER",a."MailNo"
--,a.sbsj,a.xbsj,a.kq_sbsj,a.kq_xbsj,a.kq_txsj
--,b.ksrq,b.jsrq,c.detail_fromDate,c.detail_toDate
,case when a.lastname='蔡东志' then ''
when to_char(to_date(a."SIGNDATE",'yyyy-MM-dd'),'d') in (1,7) then ''
when b.xm is not null then a.lastname||'请假'
when c.xm is not null then a.lastname||'外出'
      when nvl(a.sbsj,to_date(to_char(sysdate,'yyyy-MM-dd'),'yyyy-MM-dd'))=to_date(to_char(sysdate,'yyyy-MM-dd'),'yyyy-MM-dd')then a.lastname||'上班未打卡'
  when a.sbsj>a.kq_txsj then a.lastname||'迟到'
      when nvl(a.xbsj,to_date(to_char(sysdate,'yyyy-MM-dd'),'yyyy-MM-dd'))=to_date(to_char(sysdate,'yyyy-MM-dd'),'yyyy-MM-dd') and a.signdate!=to_char(sysdate,'yyyy-MM-dd') then a.lastname||'下班未打卡'
    when a.xbsj<a.kq_xbsj then a.lastname||'早退'
      when a.sbsj>a.kq_sbsj and a.sbsj<a.kq_txsj then a.lastname||'弹性打卡'
      else ''end "Remark"
,case when a.lastname='蔡东志' then ''
when b.xm is not null or c.xm is not null then 'background-color:#19a9d5;'
  when a.sbsj>a.kq_txsj then 'background-color:red;'
      when a.sbsj>a.kq_sbsj and a.sbsj<a.kq_txsj then 'background-color:#fad733;'
      else ''end "MinStyle"
        ,case when a.lastname='蔡东志' then ''
        when b.xm is not null or c.xm is not null then 'background-color:#19a9d5;'
      when a.xbsj<a.kq_xbsj then 'background-color:red;'
      else ''end "MaxStyle"
from data2 a left join qj b on a.userid=b.xm and a.signdate between b.ksrq and b.jsrq
left join waichu c on a.userid=c.xm and a.signdate between c.detail_fromDate and c.detail_toDate
order by a."MailNo",a.subcompanyname,a.departmentname,a.lastname,a.signdate;