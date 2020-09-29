
ALTER VIEW V_Cust_Item4OA AS
SELECT a.ID,a.Code,a.Name,a.Org,a2.Code as OrgCode,a.SPECS,a.PriceUOM,cast(a5.MinSaleQty as Float) as MinSaleQty,
a3.Code as PriceUOMCode,a4.code as CategoryCode,a4.FullName as CategoryFullName 
,mrp.Name MRPName
FROM dbo.CBO_ItemMaster AS a
INNER JOIN dbo.CBO_ItemMaster_Trl AS a1 ON a.id=a1.ID
					AND a1.SysMLFlag='zh-cn'
INNER JOIN dbo.Base_Organization AS a2 ON a.Org=a2.ID		
INNER JOIN dbo.Base_UOM AS a3 ON a.PriceUOM=a3.ID		
INNER JOIN dbo.V_Cust_Category4OA AS a4 ON a.MainItemCategory=a4.ID	
left join CBO_SaleInfo as a5 on a.SaleInfo=a5.id			
LEFT JOIN dbo.vw_MRPCategory mrp ON a.DescFlexField_PrivateDescSeg22=mrp.Code
WHERE a.Effective_IsEffective = 1
AND a.Effective_EffectiveDate <=GETDATE()
AND a.Effective_DisableDate>=GETDATE()
AND a.State = 2

GO
