/*
销售变更单单据类型
*/
CREATE VIEW v_Cust_SOModifyDocType4OA
as
SELECT 
a.Org OrgID,o.Code OrgCode,a.ID,o1.Name OrgName,a.Code,a1.Name
,a.Effective_IsEffective,a.Effective_EffectiveDate,a.Effective_DisableDate
FROM dbo.SM_SOModifyDocType a LEFT JOIN dbo.SM_SOModifyDocType_Trl a1 ON a.ID=a1.ID AND a1.SysMLFlag='zh-cn'
LEFT JOIN dbo.Base_Organization o ON a.Org=o.ID
LEFT JOIN dbo.Base_Organization_Trl o1 ON o.ID=o1.ID AND o1.SysMLFlag='zh-cn'
WHERE a.Effective_IsEffective=1


GO
