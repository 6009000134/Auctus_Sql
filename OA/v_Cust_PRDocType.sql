CREATE VIEW v_Cust_PRDocType
as
SELECT 
a.ID,a.Code,a1.Name,a.Effective_IsEffective IsEffect
,a.Org OrgID,o.Code OrgCode,o1.Name OrgName
FROM dbo.PR_PRDocType a INNER JOIN dbo.PR_PRDocType_Trl a1 ON a.ID=a1.ID AND ISNULL(a1.SysMLFlag,'zh-cn')='zh-cn'
INNER JOIN dbo.Base_Organization o ON a.Org=o.Id LEFT JOIN dbo.Base_Organization_Trl o1 ON o.ID=o1.ID AND ISNULL(o1.SysMLFlag,'zh-cn')='zh-cn'
AND a.Effective_IsEffective=1