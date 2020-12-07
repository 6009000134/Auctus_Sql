/*
ÇøÓò»®·Ö
*/
ALTER VIEW v_Cust_Area
as
SELECT  A.[ID] AS [ID] ,
        A.[Code] AS [Code] ,
        A1.[Name] AS [Name] ,
        --A.[SysVersion] AS [SysVersion] ,
        --A.[ID] AS [MainID] ,
        --A2.[Code] AS SysMlFlag ,
        ROW_NUMBER() OVER ( ORDER BY A.[Code] ASC, ( A.[ID] + 17 ) ASC ) AS rownum
FROM    Base_DefineValue AS A
        LEFT JOIN Base_Language AS A2 ON ( A2.Code = 'zh-CN' )
                                         AND ( A2.Effective_IsEffective = 1 )
        LEFT JOIN [Base_DefineValue_Trl] AS A1 ON ( A1.SysMLFlag = 'zh-CN' )
                                                  AND ( A1.SysMLFlag = A2.Code )
                                                  AND ( A.[ID] = A1.[ID] )
WHERE   A.[ValueSetDef] = 1001708040000198
        AND A.[Effective_IsEffective] = 1
        AND A.[Effective_EffectiveDate] <= GETDATE()
        AND A.[Effective_DisableDate] >= GETDATE()
                          