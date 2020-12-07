/*
Ë°×éºÏ
*/
CREATE VIEW v_Cust_TaxSchedule
AS
 SELECT A.[ID] AS [ID] ,
        A.[Code] AS [Code] ,
        A1.[Name] AS [Name] ,
        --A1.[ShortName] AS [ShortName] ,
        --A.[TaxScheduleType] AS [TaxScheduleType] ,
        --A.[SysVersion] AS [SysVersion] ,
        --A.[ID] AS [MainID] ,
        --A2.[Code] AS SysMlFlag ,
        ROW_NUMBER() OVER ( ORDER BY A.[Code] ASC, ( A.[ID] + 17 ) ASC ) AS rownum
 FROM   CBO_TaxSchedule AS A
        LEFT JOIN Base_Language AS A2 ON ( A2.Code = 'zh-CN' )
                                         AND ( A2.Effective_IsEffective = 1 )
        LEFT JOIN [CBO_TaxSchedule_Trl] AS A1 ON ( A1.SysMLFlag = 'zh-CN' )
                                                 AND ( A1.SysMLFlag = A2.Code )
                                                 AND ( A.[ID] = A1.[ID] )
 WHERE  A.[Effective_IsEffective] = 1
        AND GETDATE() BETWEEN A.[Effective_EffectiveDate]       AND     A.[Effective_DisableDate]
        AND A.[TaxScheduleType] = 1

GO
