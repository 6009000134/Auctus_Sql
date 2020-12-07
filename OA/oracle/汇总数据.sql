
select "MailNo",subcompanyname,departmentname,signdate,count(1) USERNUM
,(select count(1) from  v_auctus_hrattendmaildata t where t.subcompanyname=a.subcompanyname and t.departmentname=a.departmentname and t.signdate=a.signdate and t."MailNo"=a."MailNo" and t."Remark"!='请假')SJCQ
,(select count(1) from  v_auctus_hrattendmaildata t where t.subcompanyname=a.subcompanyname and t.departmentname=a.departmentname and t.signdate=a.signdate and t."MailNo"=a."MailNo" and t."Remark"!='弹性打卡') TXDK
,(select count(1) from  v_auctus_hrattendmaildata t where t.subcompanyname=a.subcompanyname and t.departmentname=a.departmentname and t.signdate=a.signdate and t."MailNo"=a."MailNo" and t."Remark"!='迟到')CDRS
,(select listagg(t.lastname||t."Remark",',') within group(order by t.lastname)s 
from  v_auctus_hrattendmaildata t where t.subcompanyname=a.subcompanyname and t.departmentname=a.departmentname and t.signdate=a.signdate and t."MailNo"=a."MailNo" and 
t."Remark" is not null
group by t.subcompanyname,t.departmentname,t.signdate)"Remark"
from v_auctus_hrattendmaildata a
where 1=1 
--and a."MailNo"=0 
and a.signdate=to_char(sysdate-1,'yyyy-MM-dd')
group by "MailNo",subcompanyname,departmentname,signdate
order by "MailNo",signdate,subcompanyname,departmentname




