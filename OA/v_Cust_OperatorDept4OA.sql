/*
业务员与部门关系视图
*/
CREATE VIEW v_Cust_OperatorDept4OA
as
SELECT a.ID,a.Code,a1.Name,a.Org,a2.Code as OrgCode,a.Dept,d.Code DeptCode,d1.Name DeptName
FROM dbo.CBO_Operators AS a
INNER JOIN dbo.CBO_Operators_Trl AS a1 ON a.id=a1.ID
     AND a1.SysMLFlag='zh-cn'
INNER JOIN dbo.Base_Organization AS a2 ON a.Org=a2.ID  
LEFT JOIN dbo.CBO_Department d ON a.Dept=d.ID
LEFT JOIN dbo.CBO_Department_Trl d1 ON a.Dept=d1.ID AND ISNULL(d1.SysMLFlag,'zh-cn')='zh-cn'
WHERE a.Effective_IsEffective = 1
AND a.Effective_EffectiveDate <=GETDATE()
AND a.Effective_DisableDate>=GETDATE()

