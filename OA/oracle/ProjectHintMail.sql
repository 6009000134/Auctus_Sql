create or replace view v_auctus_ProjectHintMail
as
select
t.xmmc,t.psdate,t.type
,to_date(t.PSDate,'yyyy-MM-dd')-to_date(sysdate)diff
,t.send
,t.subject
,(select listagg(email,',')within group(order by ID)ID from hrmresource where to_char(ID) in (select strvalue from fn_split(t.send,',')) )MailTO
--,'ashburn.chan@auctus.cn,zhangwei@auctus.cn,lisl@auctus.cn,perla_yu@auctus.cn,weitt@auctus.cn' CC
,'weitt@auctus.cn,panqin@auctus.com'MailCC
,t.mailbody
,'ProjectHint.xml'XMLNAME
,rownum MailNO
from (
select a.id,a.xmmc,a.requestid,to_date(sysdate)nowdate
,to_char(a.sqr)||','||to_char(a.xmjl) send
,a.ylxps as PSDate,0 Type
,'温馨提示，“'||a.xmmc||'”的预立项评审，需要在“'||a.ylxps||'”前完成，请您组织协调项目成员，按期完成评审任务，谢谢！'MailBody
,'“'||a.xmmc||'”预立项评审提醒'subject
from formtable_main_26 a 
union all
select a.id,a.xmmc,a.requestid,to_date(sysdate)nowdate
,to_char(a.sqr)||','||to_char(a.xmjl)
,a.lxps,1 Type
,'温馨提示，“'||a.xmmc||'”的立项评审，需要在“'||a.lxps||'”前完成，请您组织协调项目成员，按期完成评审任务，谢谢！'MailBody
,'“'||a.xmmc||'”立项评审提醒' subject
from formtable_main_26 a
union all
select a.id,a.xmmc,a.requestid,to_date(sysdate)nowdate
,to_char(a.sqr)||','||to_char(a.xmjl)
,a.zcps,2 Type
,'温馨提示，“'||a.xmmc||'”的转产评审，需要在“'||a.zcps||'”前完成，请您组织协调项目成员，按期完成评审任务，谢谢！'MailBody
,'“'||a.xmmc||'”转产评审提醒'subject
from formtable_main_26 a
union all
select a.id,a.xmmc,a.requestid,to_date(sysdate)nowdate
,to_char(a.sqr)||','||to_char(a.xmjl)
,a.lcps,3 Type
,'温馨提示，“'||a.xmmc||'”的量产评审，需要在“'||a.lcps||'”前完成，请您组织协调项目成员，按期完成评审任务，谢谢！'MailBody
,'“'||a.xmmc||'”量产评审提醒'subject
from formtable_main_26 a 
union all
select a.id,a.xmmc,a.requestid,to_date(sysdate)nowdate
,to_char(a.sqr)||','||to_char(a.xmjl)
,a.jxps,4 Type
,'温馨提示，“'||a.xmmc||'”的结项评审，需要在“'||a.jxps||'”前完成，请您组织协调项目成员，按期完成评审任务，谢谢！'MailBody
,'“'||a.xmmc||'”结项评审提醒'subject
from formtable_main_26 a 
)t
inner join workflow_requestbase t1 on t.requestid=t1.requestid
where to_date(t.PSDate,'yyyy-MM-dd')-to_date(sysdate)=7 and t1.currentnodetype=3

