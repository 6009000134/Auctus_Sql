/*
MRP∑÷¿‡ ”Õº
*/
CREATE VIEW vw_MRPCategory
as
SELECT T.Code,T.Name,'MRPCategory' MRPCategory FROM ( SELECT  A.[ID] as [ID], A.[Code] as [Code], A1.[Name] as [Name], A.[SysVersion] as [SysVersion], A.[ID] as [MainID], A2.[Code] as SysMlFlag
 , ROW_NUMBER() OVER(ORDER BY A.[Code] asc, (A.[ID] + 17) asc ) AS rownum  FROM  Base_DefineValue as A  left join Base_Language as A2 on (A2.Code = 'zh-CN')
  and (A2.Effective_IsEffective = 1)  left join [Base_DefineValue_Trl] as A1 on (A1.SysMlFlag = 'zh-CN') and (A1.SysMlFlag = A2.Code) and (A.[ID] = A1.[ID])
   WHERE  (((((((A.[ValueSetDef] = (SELECT ID FROM Base_ValueSetDef WHERE code='MRPCategory') ) and (A.[Effective_IsEffective] = 1)) and (A.[Effective_EffectiveDate] <= GETDATE())) 
   AND (A.[Effective_DisableDate] >= GETDATE())) and (1 = 1)) and (1 = 1)) and (1 = 1))) T 