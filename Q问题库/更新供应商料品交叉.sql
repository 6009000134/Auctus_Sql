

--1001708090008910

--UPDATE  t SET t.MinOrderQty=1,t.PurchaseBatchQty=2
--FROM CBO_SupplierItem t ,(select a.ID,a.Code,a.Name,b.MinRcvQty,b.PurchaseBatchQty FROM dbo.CBO_ItemMaster a INNER JOIN dbo.CBO_PurchaseInfo b ON a.ID=b.ItemMaster
--WHERE a.Code IN (
--'aa'
--) AND a.Org=(SELECT id FROM dbo.Base_Organization WHERE code='300'))
--t1 WHERE t.ItemInfo_ItemID=t1.ID AND t.SupplierInfo_Supplier=1001708090008910

SELECT a.ItemInfo_ItemCode,a.MinOrderQty,a.PurchaseBatchQty ,a.ItemInfo_ItemID,m.Code,a.Org,a.ID
FROM dbo.CBO_SupplierItem a INNER JOIN dbo.CBO_ItemMaster m ON a.ItemInfo_ItemID=m.ID
WHERE a.SupplierInfo_Supplier=1001708090008910
AND a.ItemInfo_ItemCode='331060080'


--SELECT 
--a.ID
--FROM dbo.CBO_Supplier a INNER JOIN dbo.CBO_Supplier_Trl a1 ON a.ID=a1.ID
--WHERE a1.Name='东莞市钜欣电子有限公司'
--AND a.Org=(SELECT id FROM dbo.Base_Organization WHERE code='300')


