/*
资产卡片单据类型
*/
CREATE VIEW v_Cust_FACardDocType4OA
AS
SELECT 
a.ID,a.Code,a1.Name,a.Org OrgID,o.Code OrgCode,o1.Name OrgName
FROM dbo.FA_AssetCardDocType a LEFT JOIN dbo.FA_AssetCardDocType_Trl a1 ON a.ID=a1.ID
LEFT JOIN dbo.Base_Organization O ON a.Org=o.ID LEFT JOIN dbo.Base_Organization_Trl o1 ON o.ID=o1.ID
WHERE a.Effective_IsEffective=1