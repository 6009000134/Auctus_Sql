create or replace view v_auctus_bugfreeinfo
as
select 
c.sqrq
,c.bugh
,c.sfjh
,c.jhbug
,b.nodeorder
,case when b.nodeorder=3 then '归档' 
when b.nodeorder=2 then '已解决'
else '未解决' end Status
,d.ID flid
,d.iname ParentType
,d.iiname ChildType--,c.gzdl,c.gzfl,c.gzsjflid
,c.wtfsjd
,e.wtfxjd
,c.wtzrfl
,f.wtlymc
,c.xmbm,c.xmmc
from workflow_requestbase a inner join workflow_flownode b on a.currentnodeid=b.nodeid
inner join formtable_main_226 c on a.requestid=c.requestid
left join AUCTUS_FAULT d on c.gzsjflid=d.id
left join uf_wtfxjd e on c.wtfsjd=e.id
left join uf_wtly f on c.wtzrfl=f.id
where a.workflowid =  40021;
