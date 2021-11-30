/*
资产处置单据类型
*/
CREATE VIEW v_Cust_FADisposalDocType4OA
AS
SELECT 
a.ID,a.Org OrgID,o.Code OrgCode,o1.Name OrgName,a.Code,a1.Name
,dbo.F_GetEnumName('UFIDA.U9.FA.FA_Enum.DisposalSourceEnum',a.DisposalSource,'zh-cn')DisposalSource
,dbo.F_GetEnumName('UFIDA.U9.FA.FA_Enum.DisposalStyleEnum',a.DisposalStyle,'zh-cn')DisposalStyle
FROM dbo.FA_FADisposalDocType a LEFT JOIN dbo.FA_FADisposalDocType_Trl a1 ON a.ID=a1.ID AND a1.SysMLFlag='zh-cn'
LEFT JOIN dbo.Base_Organization o ON a.Org=o.ID
LEFT JOIN dbo.Base_Organization_Trl o1 ON o.ID=o1.ID AND o1.SysMLFlag='zh-cn'
WHERE a.Effective_IsEffective=1

