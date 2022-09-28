/*
入库人及部门
*/
ALTER VIEW v_Cust_HandleInfo4Mes 
AS

SELECT  A.[ID] AS [ID] ,
        A.[Code] AS [Code] ,
        A1.[Name] AS [Name] ,
        A.[OperatorType] AS [OperatorType] ,
        A2.[ID] AS [DeptID] ,
        A2.[Code] AS [DeptCode] ,
        A3.[Name] AS [DeptName] ,
		a4.Code OrgCode,
        A.[SysVersion] AS [SysVersion] ,
        ROW_NUMBER() OVER ( ORDER BY A.[ID] ASC, ( A.[ID] + 17 ) ASC ) AS rownum
FROM    CBO_Operators AS A
        LEFT JOIN [CBO_Operators_Trl] AS A1 ON ( A1.SysMLFlag = 'zh-CN' )
                                               AND ( A.[ID] = A1.[ID] )
        LEFT JOIN [CBO_Department] AS A2 ON ( A.[Dept] = A2.[ID] )
        LEFT JOIN [CBO_Department_Trl] AS A3 ON ( A3.SysMLFlag = 'zh-CN' )
                                                AND ( A2.[ID] = A3.[ID] )
        LEFT JOIN [Base_Organization] AS A4 ON ( A.[Org] = A4.[ID] )
        LEFT JOIN [dbo].[Base_Organization_Trl] AS A5 ON a.Org=a5.ID AND a5.SysMLFlag='zh-cn'
WHERE   A2.[Code] LIKE '30202030%'
        AND 
		( A.[Effective_IsEffective] = 1 )
        AND A.[Effective_EffectiveDate] <= GETDATE()
        AND A.[Effective_DisableDate] >= GETDATE()
        AND A.[ID] IN ( SELECT  B.[Operators]
                        FROM    CBO_OperatorLine AS B
                        WHERE   B.[OperatorType] IN ( 2, 7 ) )
        AND A4.[ID] = 1001708020135665