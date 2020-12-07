
create or replace view v_auctus_hrattendsum
as
select a."MailNo",a.signdate,count(a.departmentname)total
,(select count(1) from v_auctus_hrattendmaildata t where t.signdate=a.signdate and t.IsQJ=1)qj
,(select count(1) from v_auctus_hrattendmaildata t where t.signdate=a.signdate and t.iswc=1)wc
,(select count(1) from v_auctus_hrattendmaildata t where t.signdate=a.signdate and t."Remark" like '%弹性打卡%')txdk
,(select count(1) from v_auctus_hrattendmaildata t where t.signdate=a.signdate and t."Remark" like '%迟到%')cd
--,listagg(a."Remark",',')within group(order by a.LASTNAME)"Remark"
from v_auctus_hrattendmaildata a 
where a."MailNo"=0
group by a."MailNo",a.signdate
order by a."MailNo";
