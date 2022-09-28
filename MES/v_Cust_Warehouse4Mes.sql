CREATE VIEW v_Cust_Warehouse4Mes
as
 SELECT A.[ID] AS [ID] ,
        A.[Code] AS [Code] ,
        A1.[Name] AS [Name] ,
        A1.[ShortName] AS [ShortName] ,
        A.[IsLot] AS [IsLot] ,
        A.[IsSerial] AS [IsSerial] ,
        A.[IsBin] AS [IsBin] ,
        A.[StorageType] AS [StorageType] ,
        A.[LocationType] AS [LocationType] ,
        A.[DepositType] AS [DepositType] ,
        A.[IsAllowNegative] AS [IsAllowNegative] ,
        A3.[ID] AS [Supplier_ID] ,
        A3.[Code] AS [Supplier_Code] ,
        A4.[Name] AS [Supplier_Name] ,
        A.[SysVersion] AS [SysVersion] ,
        A2.[Code] AS SysMlFlag ,
        ROW_NUMBER() OVER ( ORDER BY A.[ID] ASC, ( A.[ID] + 17 ) ASC ) AS rownum
 FROM   CBO_Wh AS A
        LEFT JOIN Base_Language AS A2 ON ( A2.Code = 'zh-CN' )
                                         AND ( A2.Effective_IsEffective = 1 )
        LEFT JOIN [CBO_Wh_Trl] AS A1 ON ( A1.SysMLFlag = 'zh-CN' )
                                        AND ( A1.SysMLFlag = A2.Code )
                                        AND ( A.[ID] = A1.[ID] )
        LEFT JOIN [CBO_Supplier] AS A3 ON ( A.[Supplier] = A3.[ID] )
        LEFT JOIN [CBO_Supplier_Trl] AS A4 ON ( A4.SysMLFlag = 'zh-CN' )
                                              AND ( A4.SysMLFlag = A2.Code )
                                              AND ( A3.[ID] = A4.[ID] )
 WHERE  A.[Effective_IsEffective] = 1
        AND A.[Effective_EffectiveDate] <= GETDATE() 
        AND A.[Effective_DisableDate] >=GETDATE() 
        AND A.[DepositType] NOT IN ( 0, 3 )--非VMI、寄外仓  外寄仓类型
        AND  A.[Org] = '1001708020135665' 
        AND A.[Code] NOT IN ( '101', '107', '220', '116', '113', '000000',
                              '223', '106' )
        AND A1.[Name] NOT LIKE '%委外%'

                                  
                            
                      
       