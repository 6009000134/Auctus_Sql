/*
杂收单单据类型视图
*/
CREATE VIEW v_Cust_MiscRcvDocType
as
SELECT 
a.ID,o.ID OrgID,o.code OrgCode,o1.Name OrgName,a.Code,a1.Name,a.Effective_IsEffective,a.Effective_EffectiveDate,a.Effective_DisableDate
FROM dbo.InvDoc_MiscRcvDocType a INNER JOIN dbo.InvDoc_MiscRcvDocType_Trl a1 ON a.ID=a1.ID AND ISNULL(a1.SysMLFlag,'zh-cn')='zh-cn'
INNER JOIN dbo.Base_Organization o ON a.Org=o.ID
INNER JOIN dbo.Base_Organization_Trl o1 ON o.ID=o1.ID AND ISNULL(o1.SysMLFlag,'zh-cn')='zh-cn'
WHERE a.Effective_IsEffective=1
AND GETDATE() BETWEEN a.Effective_EffectiveDate AND a.Effective_DisableDate

