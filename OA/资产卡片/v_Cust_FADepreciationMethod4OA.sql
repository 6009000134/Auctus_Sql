/*
资产卡片折旧方法
*/
CREATE VIEW v_Cust_FADepreciationMethod4OA
AS
SELECT 
a.ID,a.Code,a1.Name,a.Org OrgID,o.Code OrgCode,o1.Name OrgName
FROM dbo.FA_DepreciationMethod a LEFT JOIN dbo.FA_DepreciationMethod_Trl a1 ON a.ID=a1.ID AND a1.SysMLFlag='zh-cn'
LEFT JOIN dbo.Base_Organization O ON a.Org=o.ID LEFT JOIN dbo.Base_Organization_Trl o1 ON o.ID=o1.ID AND o1.SysMLFlag='zh-cn'
--WHERE a.Effective_IsEffective=1

