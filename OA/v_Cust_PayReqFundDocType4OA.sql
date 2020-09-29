/*
请款单据类型
*/
CREATE VIEW v_Cust_PayReqFundDocType4OA
as
SELECT  *
FROM    ( SELECT    A.[ID] AS [ID] ,
                    A.Org ,
                    o.Code OrgCode ,
                    o1.Name OrgName ,
                    A.[Code] AS [Code] ,
                    A1.[Name] AS [Name] ,
                    A.[BusinessType] AS [BusinessType] ,
                    A.[ConfirmType] AS [ConfirmType] ,
                    A1.[Description] AS [Description] ,
                    A.[DocHeaderSequenceStyle] AS [DocHeaderSequenceStyle] ,
                    A3.[Name] AS [DocHeaderSequence_Name] ,
                    A.[IsDocNoEditable] AS [IsDocNoEditable] ,
                    A.[ReqFundUse] AS [ReqFundUse] ,
					dbo.F_GetEnumName('UFIDA.U9.AP.Enums.RequestFundUseEnum',a.ReqFundUse,'zh-cn')[ReqFundUseName],
                    A.[PrePayType] AS [PrePayType] ,
					dbo.F_GetEnumName('UFIDA.U9.CBO.FI.Enums.PrePayObjEnum',a.[PrePayType],'zh-cn')[PrePayTypeName],					
                    A.[IsAutoConfirm] AS [IsAutoConfirm] ,
                    A.[SysVersion] AS [SysVersion] ,
                    ROW_NUMBER() OVER ( ORDER BY a.Org,A.[Code] ASC, ( A.[ID] + 17 ) ASC ) AS rownum
          FROM      AP_PayReqFundDocType AS A
                    LEFT JOIN [AP_PayReqFundDocType_Trl] AS A1 ON ( A1.SysMLFlag = 'zh-CN' )
                                                              AND ( A.[ID] = A1.[ID] )
                    LEFT JOIN [Base_SequenceDef] AS A2 ON ( A.[DocHeaderSequence] = A2.[ID] )
                    LEFT JOIN [Base_SequenceDef_Trl] AS A3 ON ( A3.SysMLFlag = 'zh-CN' )
                                                              AND ( A2.[ID] = A3.[ID] )
                    LEFT JOIN dbo.Base_Organization o ON A.Org = o.ID
                    LEFT JOIN dbo.Base_Organization_Trl o1 ON o.ID = o1.ID
                                                              AND ISNULL(o1.SysMLFlag,
                                                              'zh-cn') = 'zh-cn'
          WHERE     ( A.[Effective_IsEffective] = 1 )
                    AND GETDATE() BETWEEN A.[Effective_EffectiveDate]
                                  AND     A.[Effective_DisableDate]
        ) T;