/*
杂收单据类型
*/
CREATE VIEW V_Cust_MiscRcvDocType4OA AS
SELECT a.ID,a.Org,a2.Code AS OrgCode,a.Code,a1.Name FROM dbo.InvDoc_MiscRcvDocType AS a
INNER JOIN dbo.InvDoc_MiscRcvDocType_Trl AS a1 ON a1.id=a.ID AND a1.SysMLFlag='zh-cn'
INNER JOIN dbo.Base_Organization AS a2 ON a2.id=a.Org
WHERE a.Effective_IsEffective = 1
--AND a.Effective_EffectiveDate <= GETDATE()
--AND a.Effective_DisableDate >= GETDATE()

GO
