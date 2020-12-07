/*
生产领退料单据类型
*/
ALTER  VIEW v_Cust_MOIssueDocType4OA
AS
SELECT a.ID,a.Code,a1.Name,a.Org,a.Effective_IsEffective IsEffective
FROM dbo.MO_IssueDocType a INNER JOIN dbo.MO_IssueDocType_Trl a1 ON a.ID=a1.ID AND ISNULL(a1.SysMLFlag,'zh-cn')='zh-cn'


