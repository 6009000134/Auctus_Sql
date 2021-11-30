/*
预测订单单据类型
*/
ALTER VIEW v_Cust_ForecastDocType
AS
SELECT a.ID,a.Org OrgID,o.Code OrgCode,o1.Name OrgName,a.Code,b.Name,a.Effective_IsEffective,a.Effective_EffectiveDate,a.Effective_DisableDate
FROM dbo.SM_ForecastOrderDocType a INNER JOIN dbo.SM_ForecastOrderDocType_Trl b ON a.ID=b.ID AND b.SysMLFlag='zh-cn'
INNER JOIN dbo.Base_Organization o ON a.Org=o.ID INNER JOIN dbo.Base_Organization_Trl o1 ON o.ID=o1.ID AND o1.SysMLFlag='zh-cn'
WHERE a.Effective_IsEffective=1



