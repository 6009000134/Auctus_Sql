/*
线别-生产车间关系
*/
ALTER VIEW v_Cust_LineAndDept4OA
AS
   SELECT line.Code,line.Name LineName,Dept.DeptCode,Dept.DeptName FROM 
   (
   SELECT  A.[ID] as [ID], A.[Code] as [Code], A1.[Name] as [Name]
 FROM  Base_DefineValue as A  left join Base_Language as A2 on (A2.Code = 'zh-CN')
  and (A2.Effective_IsEffective = 1)  left join [Base_DefineValue_Trl] as A1 on (A1.SysMlFlag = 'zh-CN') and (A1.SysMlFlag = A2.Code) and (A.[ID] = A1.[ID])
   WHERE  (((A.[ValueSetDef] = (SELECT ID FROM Base_ValueSetDef WHERE code='ZDY_SCXB') ) and (A.[Effective_IsEffective] = 1)) and (A.[Effective_EffectiveDate] <= GETDATE())) 
   AND (A.[Effective_DisableDate] >= GETDATE())
   ) Line INNER JOIN 
   (
   SELECT dept.Code LineDeptCode,b.Code DeptCode,b1.Name DeptName
FROM (
SELECT  a.Code
 FROM  Base_DefineValue as A  left join Base_Language as A2 on (A2.Code = 'zh-CN')
  and (A2.Effective_IsEffective = 1)  left join [Base_DefineValue_Trl] as A1 on (A1.SysMlFlag = 'zh-CN') and (A1.SysMlFlag = A2.Code) and (A.[ID] = A1.[ID])
   WHERE  (A.[ValueSetDef] = (SELECT ID FROM Base_ValueSetDef WHERE code='ZDY_SCXB') ) 
   AND (A.[Effective_IsEffective] = 1) and (A.[Effective_EffectiveDate] <= GETDATE())
   AND (A.[Effective_DisableDate] >= GETDATE())
   AND LEN(a.Code)=3)dept LEFT JOIN dbo.CBO_Department b ON STUFF(dept.Code,1,1,'3')=SUBSTRING(b.Code,LEN(b.code)-2,3)
   LEFT JOIN dbo.CBO_Department_Trl b1 ON b.ID=b1.ID
   WHERE b.Org=(SELECT id FROM dbo.Base_Organization WHERE code='300') AND b.Code LIKE '30202%'
   ) Dept ON SUBSTRING(Line.Code,1,3)=Dept.LineDeptCode
   WHERE LEN(Line.Code)>3