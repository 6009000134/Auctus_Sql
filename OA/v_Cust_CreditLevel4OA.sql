--信用等级
ALTER VIEW v_Cust_CreditLevel4OA
as
SELECT a.ID,a.ReferenceLevel,a.Organization Org,a.Code,a1.Name ,b.CreditContent_CreditLimit CreditLimit
,c.SingleCurrency Currency,a.CreditPolicy
FROM dbo.CC_CreditLevel a INNER JOIN dbo.CC_CreditLevel_Trl a1 ON a.ID=a1.ID
INNER JOIN dbo.CC_CreditPolicy c ON a.CreditPolicy=c.ID
LEFT JOIN dbo.CC_CreditLevelCurrency b ON a.ID=b.CreditLevel