/*
供应商视图
*/
ALTER  VIEW vw_CBO_Supplier
AS 	
	WITH data1 AS
	(
	SELECT 
	DISTINCT s.ID Supplier
	FROM dbo.PM_PurchaseOrder a INNER JOIN dbo.PM_POLine b ON a.ID=b.PurchaseOrder
	INNER JOIN dbo.PM_POShipLine c ON b.ID=c.POLine
	INNER JOIN dbo.CBO_ItemMaster m ON c.ItemInfo_ItemID=m.ID
	LEFT JOIN dbo.CBO_Supplier s ON a.Supplier_Supplier=s.ID LEFT JOIN dbo.CBO_Supplier_Trl s1 ON s.ID=s1.ID
	WHERE a.Org=1001708020135665 AND a.Status=2 AND b.Status=2 AND c.DeficiencyQtyTU>0
	--AND s.DescFlexField_PrivateDescSeg3 NOT IN('NEI01','OT01')
	--AND m.DescFlexField_PrivateDescSeg22 IN ('MRP104','MRP105','MRP106','MRP113','MRP100','MRP101','MRP102','MRP103','MRP107')
	) 
	 SELECT a.ID,a.Code,b.Name FROM dbo.CBO_Supplier a INNER JOIN dbo.CBO_Supplier_Trl b ON a.ID=b.ID AND ISNULL(b.SysMLFlag,'zh-cn')='zh-cn' 
	 AND a.Effective_IsEffective=1 AND a.Org=1001708020135665 
	 INNER JOIN data1 c ON a.ID=c.Supplier

 
 

