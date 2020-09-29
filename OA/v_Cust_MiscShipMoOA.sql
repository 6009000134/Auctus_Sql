SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
GO
/*
杂发单可选生产订单号
*/
CREATE VIEW v_Cust_MiscShipMoOA
AS

SELECT  *
FROM    ( SELECT    A.[ID] AS [ID] ,
                    A.[DocNo] AS [MoDocNo] ,
                    A.[Version] AS [Version] ,
                    A.[BusinessDate] AS [BusinessDate] ,
                    A2.[Name] AS [MODocType_Name] ,
                    A.[SysVersion] AS [SysVersion] ,
                    A.[ID] AS [MainID] ,a3.id org,
                    ROW_NUMBER() OVER ( ORDER BY A.[BusinessDate] ASC, A.[DocNo] ASC, ( A.[ID]
                                                              + 17 ) ASC ) AS rownum
          FROM      MO_MO AS A
                    LEFT JOIN [MO_MODocType] AS A1 ON ( A.[MODocType] = A1.[ID] )
                    LEFT JOIN [MO_MODocType_Trl] AS A2 ON ( A2.SysMLFlag = 'zh-CN' )
                                                          AND ( A1.[ID] = A2.[ID] )
                    LEFT JOIN [Base_Organization] AS A3 ON ( A.[Org] = A3.[ID] )
          WHERE     ( 1 = 1 )
                      AND        A.[IsFIClose] = 0                                      
                                      AND ( A.[BusinessType] != 50 )                                   
                                    AND ( A.[BusinessType] != 52 )                                  
                                  AND  A.[IsMultiRouting] != 1                                 
                                AND A.[ItemMaster] IS NOT NULL                              
                              AND A.[DocState] IN (  2, 3 )                            
                            AND ( A.[IsFIClose] = 0 )                          
                    
        ) T; 
GO
