SELECT 
a.ID,s.Code SupplierCode,m.Code
,a.MaxCapabilityCtrl--���л�������
,a.MaxCapability--���л���
,a.DescFlexField_PrivateDescSeg1--��������
,a.DescFlexField_PrivateDescSeg2--����״̬
,a.DescFlexField_PrivateDescSeg3--������
,a.DescFlexField_PrivateDescSeg4--������Ч����
,a.MinOrderQtyCtrl--MOQ����
,a.MinOrderQty--MOQ
,a.PurchaseBatchQty--MPQ
,a.SupplyLeadTime-- ��������
,a.InspectLeadTime--��������
,a.OrderLeadTime--	������������
FROM dbo.CBO_SupplierItem a
INNER JOIN dbo.CBO_Supplier s ON a.SupplierInfo_Supplier=s.ID
INNER JOIN dbo.CBO_ItemMaster m ON a.ItemInfo_ItemID=m.ID
WHERE a.Org=(SELECT id FROM dbo.Base_Organization WHERE code='300')




--��Ʒ�����͹�Ӧ��-��Ʒ����� MOQ\MPQ\��������\�������ڲ�һ������
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

--��Ʒ�����͹�Ӧ��-��Ʒ����� MOQ\MPQ\��������\�������ڲ�һ������
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
--ί����Ȩ��ȡ��
