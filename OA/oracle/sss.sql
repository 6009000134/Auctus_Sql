select * from (
--发送给蔡总
SELECT   0 "MailNo", 'andy@auctus.cn;'  "MailTo",'蔡东志' "CHI_NAME", 'HrInfo.xml'  "XmlName"  from dual    
union all
--发送给个总监
select dense_rank() over(partition by t1.ceo order by t1.leader) "MailNo" ,'liufei@auctus.com' "MailTo",t1.leader "CHI_NAME",'HrInfo.xml' "XmlName" from 
(select distinct t.leader,t.ceo,t.LeaderMail from v_auctus_hrAttendMail t where t.signdate in ('2020-07-28','2020-07-27')) t1
where t1.leader is not null
) t order by t."MailNo"


select * from 
(
--蔡总数据
select t.lastname,t.signdate,t.mintime,t.maxtime,t.leader,0 "MailNo"
from v_auctus_hrAttendMail t
where t.signdate in ('2020-07-28','2020-07-27')
union all
--各总监数据
select t.lastname,t.signdate,t.mintime,t.maxtime,t.leader,m.mailno "MailNo"
from v_auctus_hrAttendMail t
inner join 
(
select t1.leader,dense_rank() over(partition by t1.ceo order by t1.leader) MailNo
from (
select distinct t.leader,t.ceo,t.LeaderMail
from v_auctus_hrAttendMail t
where t.signdate in ('2020-07-28','2020-07-27')
) t1
) m on t.leader=m.leader
where t.signdate in ('2020-07-28','2020-07-27')
)
order by "MailNo"




