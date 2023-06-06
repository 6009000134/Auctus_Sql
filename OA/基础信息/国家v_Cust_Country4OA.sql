/*
¹ú¼Ò
*/
CREATE VIEW v_Cust_Country4OA
as
SELECT
a.ID
,a.Code
,a1.Name
FROM dbo.Base_Country a INNER JOIN dbo.Base_Country_Trl a1 ON a.ID=a1.ID AND a1.SysMLFlag='zh-cn'
WHERE GETDATE() BETWEEN a.Effective_EffectiveDate AND a.Effective_DisableDate AND a.Effective_IsEffective=1