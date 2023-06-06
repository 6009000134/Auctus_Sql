/*
收货原则
*/
CREATE VIEW v_Cust_ReceiptRule
AS
SELECT
a.ID
,o.ID OrgID
,o.Code OrgCode
,o1.Name OrgName
,a.Code
,a1.Name
--,a.Effective_IsEffective,a.Effective_EffectiveDate,a.Effective_DisableDate
FROM dbo.CBO_ReceiptRule a INNER JOIN dbo.CBO_ReceiptRule_Trl a1 ON a.ID=a1.ID AND a1.SysMLFlag='zh-cn'
INNER JOIN dbo.Base_Organization o ON a.Org=o.ID INNER JOIN dbo.Base_Organization_Trl o1 ON o.ID=o1.ID AND o1.SysMLFlag='zh-cn'
WHERE GETDATE() BETWEEN a.Effective_EffectiveDate AND a.Effective_DisableDate AND a.Effective_IsEffective=1
