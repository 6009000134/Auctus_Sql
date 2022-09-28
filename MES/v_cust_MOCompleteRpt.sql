
/*
完工报告
*/
CREATE VIEW v_cust_MOCompleteRpt
AS

SELECT a.ID,a.Code,a1.Name,a.Org,o.Code OrgCode,o1.Name OrgName,a.Effective_IsEffective,a.Effective_EffectiveDate,a.Effective_DisableDate
 ,A.[BusinessType] ,
        A.[CompleteRptType] ,
        A.[DocHeaderSequenceStyle] ,
        A.[ConfirmType]  ,
        A.[IsRAMADoc]  ,
        A.[IsAMADoc]  ,
        A.[IsRMADoc]  ,
        A.[IsSaveSubmit]  ,
        A.[IsScrapRcv]
FROM dbo.MO_CompleteRptDocType a LEFT JOIN dbo.MO_CompleteRptDocType_Trl a1 ON a.ID=a1.ID AND ISNULL(a1.SysMLFlag,'zh-cn')='zh-cn'
LEFT JOIN dbo.Base_Organization o ON a.Org=o.ID LEFT JOIN dbo.Base_Organization_Trl o1 ON o.ID=o1.ID AND ISNULL(o1.SysMLFlag,'zh-cn')='zh-cn'
WHERE a.Org=1001708020135665


GO
