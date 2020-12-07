CREATE OR REPLACE VIEW V_AUCTUS_HRATTENDMAIL AS
with data1 as
(
select t."USERID",t."SUBCOMPANYID1",t."LASTNAME",t."DEPARTMENTID",t."SIGNDATE",t."MINTIME",t."MAXTIME"
,case when to_char(nvl(t2.LASTNAME,''))=to_char('蔡东志') then '' else t2.lastname end  Leader
,case when to_char(nvl(t2.LASTNAME,''))=to_char('蔡东志') then '' else t2.email end  LeaderMail
,'蔡东志' CEO
,(select email from hrmresource where lastname='蔡东志') CEOMail
from (
select a.userid,a.subcompanyid1,a.lastname,a.departmentid,a.signdate,min(b.signtime)MinTime,max(b.signtime)MaxTime--每人打卡情况
from v_auctus_hrmdate a
left join HrmScheduleSign b on a.userid=b.userid and a.signdate=b.signdate
where a.status in (0,1,2,3)
and a.signdate in (to_char(sysdate,'yyyy-MM-dd'),to_char(sysdate-1,'yyyy-MM-dd'))
group by a.userid,a.subcompanyid1,a.departmentid,a.signdate,a.lastname
) t left join table(f_userrelate())  t1 on t.userid=t1.userid left join hrmresource t2 on t1.leader=t2.id
)
select "MailNo","MailTo","CHI_NAME","XmlName",'liufei@auctus.com'"MailBcc"
,to_char(sysdate-1,'yyyy-MM-dd')||','||to_char(sysdate,'yyyy-MM-dd') "DateData"
from (
--发送给蔡总
SELECT   0 "MailNo", 'liufei@auctus.com'  "MailTo",'蔡东志' "CHI_NAME", 'HrInfo.xml'  "XmlName"
--SELECT   0 "MailNo", 'andy@auctus.cn'  "MailTo",'蔡东志' "CHI_NAME", 'HrInfo.xml'  "XmlName"
from dual
union all
--发送给个总监
select dense_rank() over(partition by t1.ceo order by t1.leader) "MailNo" ,'liufei@auctus.com' "MailTo",t1.leader "CHI_NAME",'HrInfo.xml' "XmlName"
--select dense_rank() over(partition by t1.ceo order by t1.leader) "MailNo" ,nvl(t1.LeaderMail,'liufei@auctus.com') "MailTo",t1.leader "CHI_NAME",'HrInfo.xml' "XmlName"
from
(
select distinct t.leader,t.ceo,t.LeaderMail from data1 t
)t1
where t1.leader is not null
) t
where "MailNo"=0
order by t."MailNo";
