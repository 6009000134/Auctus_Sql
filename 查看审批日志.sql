SELECT  *
FROM    ( SELECT    
					pm.docno,
A.[ID] AS [ID] ,
                    A.[CreatedOn] AS [CreatedOn] ,
                    A.[CreatedBy] AS [CreatedBy] ,
                    A.[ModifiedOn] AS [ModifiedOn] ,
                    A.[ModifiedBy] AS [ModifiedBy] ,
                    A.[SysVersion] AS [SysVersion] ,
                    A.[OperateUser] AS [OperateUser] ,
                    A1.[Code] AS [OperateUser_Code] ,
                    A1.[Name] AS [OperateUser_Name] ,
                    A.[DoTime] AS [DoTime] ,
                    A.[Remark] AS [Remark] ,
                    A.[TackState] AS [TackState] ,
                    A.[EndTime] AS [EndTime] ,
                    A.[Exception] AS [Exception] ,
                    A.[Operation] AS [Operation] ,
                    A2.[Action] AS [Action] ,
                    A.[ProcessTrack] AS [ProcessTrack] ,
                    A.[DoContext] AS [DoContext] ,
                    A.[OrderID] AS [OrderID] ,
                    A.[FlowInstance] AS [FlowInstance] ,
                    A.[StateQueueName] AS [StateQueueName] ,
                    A4.[Instance] AS [FlowInstance_Instance] ,
                    A4.[DefineXML] AS [FlowInstance_DefineXML] ,
                    A.[Title] AS [Title] ,
                    A.[IsRowLog] AS [IsRowLog] ,
                    A4.[InnerDefineVersion] AS [FlowInstance_InnerDefineVersion] ,
                    A5.[DisplayName] AS [OperateUser_DisplayName] ,
                    A3.[Code] AS SysMlFlag ,
                    ROW_NUMBER() OVER ( ORDER BY ( A.CreatedOn ) desc ) AS rownum
          FROM      CS_Workflow_ProcessTrackLog AS A
                    LEFT JOIN [Base_User] AS A1 ON ( A.[OperateUser] = A1.[ID] )
                    LEFT JOIN Base_Language AS A3 ON ( A3.Effective_IsEffective = 1 )
                    LEFT JOIN [CS_Workflow_ProcessTrackLog_Trl] AS A2 ON ( A2.SysMLFlag = A3.Code )
                                                              AND ( A.[ID] = A2.[ID] )
                    LEFT JOIN [CS_Workflow_FlowInstance] AS A4 ON ( A.[FlowInstance] = A4.[ID] )
                    LEFT JOIN [Base_User_Trl] AS A5 ON ( A5.SysMLFlag = A3.Code )
                                                       AND ( A1.[ID] = A5.[ID] )
													   LEFT JOIN dbo.PM_PurchaseOrder pm ON a4.ID=pm.FlowInstance
          --WHERE     ( A4.[Instance] = '444e6502-9714-4c39-93df-2b53704c0953' )
		  WHERE pm.Org=1001708020135665
        ) T
WHERE   T.rownum > 0
        --AND T.rownum <= 2200 
		AND t.OperateUser_Name LIKE '%гр%'
		ORDER BY t.CreatedOn DESC
        
		--SELECT a.FlowInstance FROM dbo.PM_PurchaseOrder a 
		
		--SELECT * FROM [CS_Workflow_FlowInstance] a WHERE a.ID IN(SELECT FlowInstance FROM dbo.PM_PurchaseOrder WHERE Org=1001708020135665)

