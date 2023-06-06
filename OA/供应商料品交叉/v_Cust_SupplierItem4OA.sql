CREATE VIEW v_Cust_SupplierItem4OA
as
SELECT a.ID,a.Org,o.Code OrgCode,o1.Name OrgName
,a.SupplierInfo_Supplier SupplierID,s.Code SupplierCode,s1.Name SupplierName
,a.ItemInfo_ItemID ItemID,m.Code ItemCode,m.Name ItemName
,a.SupplierItemCode,a1.SupplierItemName
,a.Effective_IsEffective,a.Effective_EffectiveDate,a.Effective_DisableDate
FROM dbo.CBO_SupplierItem a  INNER JOIN dbo.CBO_SupplierItem_Trl a1 ON a.id=a1.ID AND a1.SysMLFlag='zh-cn'
INNER JOIN dbo.Base_Organization o ON a.Org=o.ID INNER JOIN dbo.Base_Organization_Trl o1 ON o.id=o1.ID AND o1.SysMLFlag='zh-cn'
INNER JOIN dbo.CBO_ItemMaster m ON a.ItemInfo_ItemID=m.ID
INNER JOIN dbo.CBO_Supplier s ON a.SupplierInfo_Supplier=s.ID
INNER JOIN dbo.CBO_Supplier_Trl s1 ON s.ID=s1.ID AND s1.SysMLFlag='zh-cn'