


--drop view V_Cust_U9MiscShipType4OA
--杂发单单据类型
ALTER  VIEW [dbo].[V_Cust_U9MiscShipType4OA] AS
SELECT a.Org,a2.Code AS OrgCode,a.Code,a.ID,a1.Name FROM dbo.InvDoc_MiscShipDocType AS a
INNER JOIN dbo.InvDoc_MiscShipDocType_Trl AS a1 ON a1.id=a.ID AND a1.SysMLFlag='zh-cn'
INNER JOIN dbo.Base_Organization AS a2 ON a2.id=a.Org
WHERE a.Effective_IsEffective = 1
AND a.Effective_EffectiveDate <= GETDATE()
AND a.Effective_DisableDate >= GETDATE()

GO
