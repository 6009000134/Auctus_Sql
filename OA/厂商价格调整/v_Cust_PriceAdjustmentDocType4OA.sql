SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
GO
/*
厂商价格调整单据类型
*/
CREATE VIEW v_Cust_PriceAdjustmentDocType4OA
AS
SELECT 
a.ID,a.Code,a1.Name,a.Org OrgID,o.Code OrgCode,o1.Name OrgName,a.Effective_IsEffective,a.Effective_EffectiveDate,a.Effective_DisableDate
FROM dbo.PPR_PurPriceAdjustmentDocType a LEFT JOIN dbo.PPR_PurPriceAdjustmentDocType_Trl a1 ON a.ID=a1.ID
LEFT JOIN dbo.Base_Organization O ON a.Org=o.ID LEFT JOIN dbo.Base_Organization_Trl o1 ON o.ID=o1.ID
--WHERE a.Effective_IsEffective=1