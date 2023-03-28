SELECT  A.[ID] AS [ID] ,
        A.[CreatedOn] AS [CreatedOn] ,
        A.[CreatedBy] AS [CreatedBy] ,
        A.[ModifiedOn] AS [ModifiedOn] ,
        A.[ModifiedBy] AS [ModifiedBy] ,
        A.[SysVersion] AS [SysVersion] ,
        A.[WorkflowDefine] AS [WorkflowDefine] ,
        A.[DocumentType] AS [DocumentType] ,
        A2.[Name] AS [DocumentType_Name] ,
        A1.[Code] AS [DocumentType_Code] ,
        A4.[Title] AS [Title] ,
        A.[CreateUser] AS [CreateUser] ,
        A5.[Code] AS [CreateUser_Code] ,
        A.[CreateTime] AS [CreateTime] ,
        A.[State] AS [State] ,
        A.[UpdateUser] AS [UpdateUser] ,
        A6.[Code] AS [UpdateUser_Code] ,
        A.[UpdateTime] AS [UpdateTime] ,
        A4.[Desp] AS [Desp] ,
        A.[WorkflowID] AS [WorkflowID] ,
        A.[DefaultOrg] AS [DefaultOrg] ,
        A7.[Code] AS [DefaultOrg_Code] ,
        A8.[Name] AS [DefaultOrg_Name] ,
        A1.[EntityType] AS [DocumentType_EntityType] ,
        A6.[Name] AS [UpdateUser_Name] ,
        A5.[Name] AS [CreateUser_Name] ,
        A.[Content] AS [Content] ,
        A.[VersionNum] AS [VersionNum] ,
        A.[ApproveModifyOptions] AS [ApproveModifyOptions] ,
        A.[StartUserMessageTypeOptions] AS [StartUserMessageTypeOptions] ,
        A.[SourceUserMessageTypeOptions] AS [SourceUserMessageTypeOptions] ,
        A3.[Code] AS SysMlFlag
FROM    CS_Workflow_OperateFlow AS A
        LEFT JOIN [Approval_DocumentType] AS A1 ON ( A.[DocumentType] = A1.[ID] )
        LEFT JOIN Base_Language AS A3 ON ( A3.Effective_IsEffective = 1 )
        LEFT JOIN [Approval_DocumentType_Trl] AS A2 ON ( A2.SysMLFlag = A3.Code )
                                                       AND ( A1.[ID] = A2.[ID] )
        LEFT JOIN [CS_Workflow_OperateFlow_Trl] AS A4 ON ( A4.SysMLFlag = A3.Code )
                                                         AND ( A.[ID] = A4.[ID] )
        LEFT JOIN [Base_User] AS A5 ON ( A.[CreateUser] = A5.[ID] )
        LEFT JOIN [Base_User] AS A6 ON ( A.[UpdateUser] = A6.[ID] )
        LEFT JOIN [Base_Organization] AS A7 ON ( A.[DefaultOrg] = A7.[ID] )
        LEFT JOIN [Base_Organization_Trl] AS A8 ON ( A8.SysMLFlag = A3.Code )
                                                   AND ( A7.[ID] = A8.[ID] )
WHERE   ( A.[ID] = 1001709090019103 )
ORDER BY ( A.[ID] + 17 ) ASC;

SELECT 
* 
FROM CS_Workflow_OperateFlow WHERE id=1001709090019103
SELECT 
* 
FROM CS_Workflow_WorkflowDefine a LEFT JOIN dbo.CS_Workflow_OperateFlow b ON a.ID=b.WorkflowDefine
WHERE a.ID=1001709090019104