/*
资产卡片-资产类别
*/
CREATE VIEW v_Cust_FAAssetCategory4OA
AS
SELECT 
a.ID,a.Code,a1.Name,a.Org OrgID,o.Code OrgCode,o1.Name OrgName
FROM dbo.FA_AssetCategory a LEFT JOIN dbo.FA_AssetCategory_trl a1 ON a.ID=a1.ID AND a1.SysMLFlag='zh-cn'
LEFT JOIN dbo.Base_Organization O ON a.Org=o.ID LEFT JOIN dbo.Base_Organization_Trl o1 ON o.ID=o1.ID AND o1.SysMLFlag='zh-cn'


