
ALTER VIEW V_Cust_Supplier4OA AS

SELECT a.ID,a.Code,a1.Name,a.Org,a2.Code as OrgCode 
,c.Code TradeCurrency,c1.Code CheckCurrency
FROM dbo.CBO_Supplier AS a
INNER JOIN dbo.CBO_Supplier_Trl AS a1 ON a.id=a1.ID
					AND a1.SysMLFlag='zh-cn'
INNER JOIN dbo.Base_Organization AS a2 ON a.Org=a2.ID					
LEFT JOIN dbo.Base_Currency c ON a.TradeCurrency=c.ID
LEFT JOIN dbo.Base_Currency c1 ON a.CheckCurrency=c1.ID
WHERE a.Effective_IsEffective = 1
AND a.Effective_EffectiveDate <=GETDATE()
AND a.Effective_DisableDate>=GETDATE()
AND a.IsHoldRelease=0
AND a.State = 0

GO
