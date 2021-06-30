/*
完工报告
*/
CREATE VIEW v_cust_MOCompleteRpt
AS

SELECT a.ID,a.Code,a1.Name,a.Org,a.Effective_IsEffective,a.Effective_EffectiveDate,a.Effective_DisableDate
FROM dbo.MO_CompleteRptDocType a LEFT JOIN dbo.MO_CompleteRptDocType_Trl a1 ON a.ID=a1.ID AND ISNULL(a1.SysMLFlag,'zh-cn')='zh-cn'

