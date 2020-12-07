/*
查询U9线别，线别名称=线别值集中上级+线别名称
*/
CREATE VIEW vw_AssemblyLine
AS

WITH data1 AS
(
 SELECT A.[ID] AS [ID] ,
        A.[Code] AS [Code] ,
        A1.[Name] AS [Name] ,
        A.[SysVersion] AS [SysVersion] ,
        A.[ID] AS [MainID] ,
        A2.[Code] AS SysMlFlag ,
        A.Level ,
        A.ParentNode ,
        ROW_NUMBER() OVER ( ORDER BY A.[Code] ASC, ( A.[ID] + 17 ) ASC ) AS rownum
 FROM   Base_DefineValue AS A
        LEFT JOIN Base_Language AS A2 ON ( A2.Code = 'zh-CN' )
                                         AND ( A2.Effective_IsEffective = 1 )
        LEFT JOIN [Base_DefineValue_Trl] AS A1 ON ( A1.SysMLFlag = 'zh-CN' )
                                                  AND ( A1.SysMLFlag = A2.Code )
                                                  AND ( A.[ID] = A1.[ID] )
 WHERE  ( ( ( ( A.[ValueSetDef] = ( SELECT    ID
                                          FROM      Base_ValueSetDef
                                          WHERE     Code = 'ZDY_SCXB'
                                        ) )
                    AND ( A.[Effective_IsEffective] = 1 )
                  )
                  AND ( A.[Effective_EffectiveDate] <= GETDATE() )
                )
          AND ( A.[Effective_DisableDate] >= GETDATE() )
        )
		)
		SELECT a.ID,a.Code,a.name,a.ParentNode FROM data1 a WHERE ISNULL(a.ParentNode,0)=0
		UNION ALL
        SELECT b.ID,b.Code,a.Name+'-'+b.Name,b.ParentNode FROM data1 a INNER JOIN data1 b ON a.ID=b.ParentNode
 