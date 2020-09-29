/*
工单单据类型
*/
ALTER VIEW v_Cust_MODocType4OA
AS
SELECT a.ID,a.Code,b.Name,o.ID OrgID,o.Code OrgCode,o1.Name OrgName
FROM dbo.MO_MODocType a INNER JOIN dbo.MO_MODocType_Trl b ON a.ID=b.ID AND ISNULL(b.SysMLFlag,'zh-cn')='zh-cn'
INNER JOIN dbo.Base_Organization o ON a.Org=o.ID INNER JOIN dbo.Base_Organization_Trl o1 ON o.ID=o1.ID AND ISNULL(o1.SysMLFlag,'zh-cn')='zh-cn'
WHERE a.Effective_IsEffective = 1
AND a.Effective_EffectiveDate <= GETDATE()
AND a.Effective_DisableDate >= GETDATE()