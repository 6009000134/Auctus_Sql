exec [dbo].[MRP_VerifyItemLLC] '30-MPS'

select  * from MRP_ExceedItemLLC

delete  from MRP_ExceedItemLLC

select item, code,count(-1) from MRP_ExceedItemLLC
group by item,code
having count(-1)>16


select c.code,a.* from cbo_bommaster a
inner join cbo_bomcomponent b on a.id =b.bommaster
inner join cbo_itemmaster c on a.itemmaster =c.id
--inner join mrp_bommapping_temp d on a.id =d.bommaster
where b.itemmaster=1002008170178615 and a.disabledate>getdate()

select c.code,d.code,a.* from cbo_bommaster a
inner join cbo_bomcomponent b on a.id =b.bommaster
inner join cbo_itemmaster c on a.itemmaster =c.id
inner join cbo_itemmaster d on b.itemmaster =d.id
where b.itemmaster in(1002008310130293,1002007130071214,1002007210091474,1001810312635981,1001904100031524,1002004210025988,
1002007210091452,
1002007311003083,
1002008310130109,
1002012070027437) and a.disabledate>getdate()

select c.code,d.code,b.* from cbo_bommaster a
inner join cbo_bomcomponent b on a.id =b.bommaster
inner join cbo_itemmaster c on a.itemmaster =c.id
inner join cbo_itemmaster d on b.itemmaster =d.id
where b.itemmaster in(1002012070027354) and a.disabledate>getdate()