select  * from MRP_ExceedItemLLC

exec sp_bomloopcheck 'zh-cn'


select b.IsSubst,a.ID PlanName,b.ID PlanVersion,c.workcalendar,b.* from MRP_PlanName a
inner join mrp_planversion b on a.id = b.planname
inner join mrp_planparams c on a.org =c.planorg
where a.plancode='30-MPS';

select a.* from MRP_expanditemmapping_temp a
inner join cbo_itemmaster b on a.item=b.id
where a.planversion=1001905311704959