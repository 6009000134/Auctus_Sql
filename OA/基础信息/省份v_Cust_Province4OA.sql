/*
Ê¡·Ý
*/
CREATE VIEW v_Cust_Province4OA
as
SELECT
a.ID
,a.Code
,a.Country
,a1.Name
FROM dbo.Base_Province a INNER JOIN dbo.Base_Province_Trl a1 ON a.ID=a1.ID AND a1.SysMLFlag='zh-cn'
WHERE GETDATE() BETWEEN a.Effective_EffectiveDate AND a.Effective_DisableDate AND a.Effective_IsEffective=1