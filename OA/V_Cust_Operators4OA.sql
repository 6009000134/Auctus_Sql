
ALTER VIEW V_Cust_Operators4OA AS
SELECT a.ID,a.Code,a1.Name,a.Org,a2.Code as OrgCode,a.Dept,d.Code DeptCode,d1.Name DeptName,
dbo.F_GetEnumName('UFIDA.U9.CBO.HR.Operator.OperatorTypeEnum',a3.OperatorType,'zh-CN') AS OPType FROM dbo.CBO_Operators AS a
INNER JOIN dbo.CBO_Operators_Trl AS a1 ON a.id=a1.ID
     AND a1.SysMLFlag='zh-cn'
INNER JOIN dbo.Base_Organization AS a2 ON a.Org=a2.ID  
INNER JOIN dbo.CBO_OperatorLine AS a3 ON a3.Operators = a.ID   
LEFT JOIN dbo.CBO_Department d ON a.Dept=d.ID 
LEFT JOIN dbo.CBO_Department_Trl d1 ON a.Dept=d1.ID AND ISNULL(d1.SysMLFlag,'zh-cn')='zh-cn'
WHERE a.Effective_IsEffective = 1
AND a.Effective_EffectiveDate <=GETDATE()
AND a.Effective_DisableDate>=GETDATE();
GO
