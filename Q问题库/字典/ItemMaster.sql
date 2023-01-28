/*
料品档案MOQ\MPQ\采购周期同步到供应商料品价差表
*/

SELECT 
a.ID,a.Code
,p.MinRcvQty--MOQ
,p.PurchaseBatchQty--MPQ
,mrp.PurBackwardProcessLT--	采购后提前期(天)
,mrp.PurForwardProcessLT--	采购预提前期(天)
,mrp.PurProcessLT--采购处理提前期(天)
,mrp.FixedLT--固定提前期(天)
,mrp.LTBatch--	提前期批量
,mrp.SumLT--汇总提前期(天)
,mrp.DemandRule--需求分类规则:严格/非严格
,mrp.IsControlByDC--是否需求分类号控制
FROM dbo.CBO_ItemMaster a 
INNER JOIN dbo.CBO_PurchaseInfo p ON a.ID=p.ItemMaster
INNER JOIN dbo.CBO_InventoryInfo i ON a.ID=i.ItemMaster
INNER JOIN dbo.CBO_MrpInfo mrp ON a.ID=mrp.ItemMaster
WHERE a.org=(SELECT id FROM dbo.Base_Organization WHERE code='300')
