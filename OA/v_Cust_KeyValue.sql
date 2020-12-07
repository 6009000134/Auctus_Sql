/*
÷µºØ ”Õº
*/
ALTER VIEW v_Cust_KeyValue 
AS 
 SELECT    A.[ID] AS [ID] ,
                    A.[Code] AS [Code] ,
                    A1.[Name] AS [Name] ,
                    A2.[Code] AS SysMlFlag ,
					d.code GroupCode
          FROM      Base_DefineValue AS A
                    LEFT JOIN Base_Language AS A2 ON ( A2.Code = 'zh-CN' )
                                                     AND ( A2.Effective_IsEffective = 1 )
                    LEFT JOIN [Base_DefineValue_Trl] AS A1 ON ( A1.SysMLFlag = 'zh-CN' )
                                                              AND ( A1.SysMLFlag = A2.Code )
                                                              AND ( A.[ID] = A1.[ID] )
															  LEFT JOIN dbo.Base_ValueSetDef d ON a.ValueSetDef=d.ID
          WHERE      ( A.[Effective_IsEffective] = 1 )
                              
                              AND ( A.[Effective_EffectiveDate] <= GETDATE() )
                            
                            AND ( A.[Effective_DisableDate] >= GETDATE() )
                         UNION ALL
                          SELECT  
   A.[ID] AS [A_ID] ,
                    A.[Code]  ,
                    A1.[Name]  ,
                    A2.[Code] AS SysMlFlag ,
					e.Code GroupCode
          FROM      UBF_Sys_ExtEnumValue AS A
                    LEFT JOIN Base_Language AS A2 ON ( A2.Effective_IsEffective = 1 )
                    LEFT JOIN [UBF_Sys_ExtEnumValue_Trl] AS A1 ON ( A1.SysMLFlag = A2.Code )
                                                              AND ( A.[ID] = A1.[ID] )
															  INNER JOIN Base_ValueSetDef e ON a.ExtEnumType=e.EnumType
    
