﻿create or replace view v_auctus_hrattnedmaildatasum as
select a."MailNo",a.signdate,a.departmentname,count(a.departmentname)total
,(select count(1) from v_auctus_hrattendmaildata t where t.signdate=a.signdate and  t."MailNo"=a."MailNo" and a.departmentname=t.departmentname and t."Remark" like '%请假%')qj
,(select count(1) from v_auctus_hrattendmaildata t where t.signdate=a.signdate and  t."MailNo"=a."MailNo" and a.departmentname=t.departmentname and t."Remark" like '%外出%')wc
,(select count(1) from v_auctus_hrattendmaildata t where t.signdate=a.signdate and  t."MailNo"=a."MailNo" and a.departmentname=t.departmentname and t."Remark" like '%弹性打卡%')txdk
,(select count(1) from v_auctus_hrattendmaildata t where t.signdate=a.signdate and  t."MailNo"=a."MailNo" and a.departmentname=t.departmentname and t."Remark" like '%迟到%')cd
,listagg(a."Remark",',')within group(order by a.LASTNAME)"Remark"
from v_auctus_hrattendmaildata a
group by a."MailNo",a.departmentname,a.signdate
order by a."MailNo",a.departmentname;
