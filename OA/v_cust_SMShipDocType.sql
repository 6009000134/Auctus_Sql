/*
出货单据类型
*/
ALTER VIEW v_cust_SMShipDocType
AS
SELECT a.ID,a.Org,a.Code,a1.Name,a.Effective_IsEffective,a.Effective_EffectiveDate,a.Effective_DisableDate
FROM dbo.SM_ShipDocType a INNER JOIN dbo.SM_ShipDocType_Trl a1 ON a.ID=a1.ID AND ISNULL(a1.SysMLFlag,'zh-cn')='zh-cn'