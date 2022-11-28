SELECT * FROM ( SELECT  A.[ID] as [ID], A.[Code] as [Code], A1.[Name] as [Name], A.[ShortName] as [ShortName], A1.[Description] as [Description], A.[FromDate] as [FromDate], A.[ToDate] as [ToDate], A.[SysVersion] as [SysVersion], A.[ID] as [MainID], A2.[Code] as SysMlFlag , ROW_NUMBER() OVER(ORDER BY A.[Code] asc, A1.[Name] asc, (A.[ID] + 17) asc ) AS rownum  
FROM  Base_WorkCalendar as A  
left join Base_Language as A2 on (A2.Code = 'zh-CN') and (A2.Effective_IsEffective = 1)  
left join [Base_WorkCalendar_Trl] as A1 on (A1.SysMlFlag = 'zh-CN') and (A1.SysMlFlag = A2.Code) and (A.[ID] = A1.[ID]) 
WHERE  ((((A.[IsCompiled] = 1) and (1 = 1)) and (1 = 1)) and (1 = 1))) T 

select * from base_workcalendar