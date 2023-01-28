SELECT 
a.ID,s.Code SupplierCode,m.Code
,a.MaxCapabilityCtrl--最大叫货量控制
,a.MaxCapability--最大叫货量
,a.DescFlexField_PrivateDescSeg1--量产承认
,a.DescFlexField_PrivateDescSeg2--承认状态
,a.DescFlexField_PrivateDescSeg3--承认人
,a.DescFlexField_PrivateDescSeg4--承认生效日期
,a.MinOrderQtyCtrl--MOQ控制
,a.MinOrderQty--MOQ
,a.PurchaseBatchQty--MPQ
,a.SupplyLeadTime-- 供货周期
,a.InspectLeadTime--检验周期
,a.OrderLeadTime--	订单处理周期
FROM dbo.CBO_SupplierItem a
INNER JOIN dbo.CBO_Supplier s ON a.SupplierInfo_Supplier=s.ID
INNER JOIN dbo.CBO_ItemMaster m ON a.ItemInfo_ItemID=m.ID
WHERE a.Org=(SELECT id FROM dbo.Base_Organization WHERE code='300')




--料品档案和供应商-料品交叉表 MOQ\MPQ\供货周期\检验周期不一致数据
SELECT 
a.ID,a.MinOrderQty,a.PurchaseBatchQty,a.OrderLeadTime,a.InspectLeadTime,a.SupplyLeadTime
,a1.*
,b.Code,p.MinRcvQty,p.PurchaseBatchQty ,mrp.PurBackwardProcessLT,mrp.PurProcessLT
FROM dbo.CBO_SupplierItem a ,dbo.CBO_SupplierItem_Trl a1, dbo.CBO_ItemMaster b ,dbo.CBO_PurchaseInfo p,dbo.CBO_MrpInfo mrp
WHERE a.ItemInfo_ItemID=b.ID AND a.ItemInfo_ItemID=p.ItemMaster AND a.ItemInfo_ItemID=mrp.ItemMaster
AND a.ID=a1.ID AND a1.SysMLFlag='zh-cn'
AND b.Org=(SELECT id FROM dbo.Base_Organization WHERE code='300')
AND a.MinOrderQtyCtrl=1 AND PATINDEX('3%',b.Code)>0
AND a.Effective_IsEffective=1
AND b.Effective_IsEffective=1
AND GETDATE() BETWEEN a.Effective_EffectiveDate AND a.Effective_DisableDate
--AND (a.MinOrderQty!=p.MinRcvQty OR a.PurchaseBatchQty!=p.PurchaseBatchQty OR a.InspectLeadTime!=mrp.PurBackwardProcessLT OR a.SupplyLeadTime!=mrp.PurProcessLT)
AND b.Code='314040003'

--料品档案和供应商-料品交叉表 MOQ\MPQ\供货周期\检验周期不一致数据
UPDATE a SET a.MinOrderQty=p.MinRcvQty,a.PurchaseBatchQty=p.PurchaseBatchQty,a.InspectLeadTime=mrp.PurBackwardProcessLT
,a.SupplyLeadTime=mrp.PurProcessLT
FROM dbo.CBO_SupplierItem a , dbo.CBO_ItemMaster b ,dbo.CBO_PurchaseInfo p,dbo.CBO_MrpInfo mrp
WHERE a.ItemInfo_ItemID=b.ID AND a.ItemInfo_ItemID=p.ItemMaster AND a.ItemInfo_ItemID=mrp.ItemMaster
AND b.Org=(SELECT id FROM dbo.Base_Organization WHERE code='300')
AND a.MinOrderQtyCtrl=1 AND PATINDEX('3%',b.Code)>0
AND a.Effective_IsEffective=1
AND b.Effective_IsEffective=1
AND GETDATE() BETWEEN a.Effective_EffectiveDate AND a.Effective_DisableDate
AND (a.MinOrderQty!=p.MinRcvQty OR a.PurchaseBatchQty!=p.PurchaseBatchQty OR a.InspectLeadTime!=mrp.PurBackwardProcessLT OR a.SupplyLeadTime!=mrp.PurProcessLT)
--SM30202211030
--委外物权的取消
