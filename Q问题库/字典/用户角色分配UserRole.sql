--�û���ɫ
DECLARE @Org BIGINT=(SELECT id FROM dbo.Base_Organization WHERE code='200')
DECLARE @UserName VARCHAR(50)='���»�',@UserName1 VARCHAR(50)='������'
;
WITH data1 AS
(
SELECT  *,@UserName MC
FROM    ( SELECT    A.[ID] AS [ID] ,
                    A.[CreatedOn] AS [CreatedOn] ,
                    A.[CreatedBy] AS [CreatedBy] ,
                    A.[ModifiedOn] AS [ModifiedOn] ,
                    A.[ModifiedBy] AS [ModifiedBy] ,
                    A.[SysVersion] AS [SysVersion] ,
                    A.[UserOrg] AS [UserOrg] ,
                    A.[Role] AS [Role] ,
                    A1.[Code] AS [Role_Code] ,
                    A2.[Name] AS [Role_Name] ,
                    A3.[Code] AS SysMlFlag ,
                    ROW_NUMBER() OVER ( ORDER BY ( A.[ID] + 17 ) ASC ) AS rownum
          FROM      Base_UserOrgRole AS A
                    LEFT JOIN [Base_Role] AS A1 ON ( A.[Role] = A1.[ID] )
                    LEFT JOIN Base_Language AS A3 ON ( A3.Effective_IsEffective = 1 )
                    LEFT JOIN [Base_Role_Trl] AS A2 ON ( A2.SysMLFlag = A3.Code )
                                                       AND ( A1.[ID] = A2.[ID] )
          WHERE     ( ( A.[UserOrg] = (SELECT ID FROM Base_UserOrg t WHERE t.[User]=(SELECT id FROM dbo.Base_User WHERE name=@UserName) AND org=@Org) )
                      AND ( A1.[Type] != 1 )
                    )
        ) T
),
data2 AS
(
SELECT  *,@UserName1 MC
FROM    ( SELECT    A.[ID] AS [ID] ,
                    A.[CreatedOn] AS [CreatedOn] ,
                    A.[CreatedBy] AS [CreatedBy] ,
                    A.[ModifiedOn] AS [ModifiedOn] ,
                    A.[ModifiedBy] AS [ModifiedBy] ,
                    A.[SysVersion] AS [SysVersion] ,
                    A.[UserOrg] AS [UserOrg] ,
                    A.[Role] AS [Role] ,
                    A1.[Code] AS [Role_Code] ,
                    A2.[Name] AS [Role_Name] ,
                    A3.[Code] AS SysMlFlag ,
                    ROW_NUMBER() OVER ( ORDER BY ( A.[ID] + 17 ) ASC ) AS rownum
          FROM      Base_UserOrgRole AS A
                    LEFT JOIN [Base_Role] AS A1 ON ( A.[Role] = A1.[ID] )
                    LEFT JOIN Base_Language AS A3 ON ( A3.Effective_IsEffective = 1 )
                    LEFT JOIN [Base_Role_Trl] AS A2 ON ( A2.SysMLFlag = A3.Code )
                                                       AND ( A1.[ID] = A2.[ID] )
          WHERE     ( ( A.[UserOrg] = (SELECT ID FROM Base_UserOrg t WHERE t.[User]=(SELECT id FROM dbo.Base_User WHERE name=@UserName1) AND org=@Org)  )
                      AND ( A1.[Type] != 1 )
                    )
        ) T
)
SELECT a.MC,a.Role,a.Role_Code,a.Role_Name,b.MC,b.Role,b.Role_Code,b.Role_Name FROM data1 a FULL JOIN data2 b ON a.Role_Code=b.Role_Code
--SELECT id,CreatedBy,Name FROM dbo.Base_User WHERE name='��ռ��'
--SELECT * FROM Base_UserOrg t WHERE t.[User]=(SELECT id FROM dbo.Base_User WHERE name='��СӢ') AND org=1001708020135665




		


		--�û���ɫ

--�û���ɫ
--SELECT  t.Code ��֯����,t.Name ����,t.Role ��ɫid,t.Role_Code ��ɫ����,t.Role_Name ��ɫ����
--FROM    ( SELECT   
--                    A.[Role] AS [Role] ,
--                    A1.[Code] AS [Role_Code] ,
--                    A2.[Name] AS [Role_Name] ,
--                    A3.[Code] AS SysMlFlag ,
--					uo.[USER],
--					o.Code,
--					u.name,uo.org,

--					u.Effective_IsEffective,					
--                    ROW_NUMBER() OVER ( ORDER BY ( A.[ID] + 17 ) ASC ) AS rownum
--          FROM      Base_UserOrgRole AS A
--                    LEFT JOIN [Base_Role] AS A1 ON ( A.[Role] = A1.[ID] )
--                    LEFT JOIN Base_Language AS A3 ON ( A3.Effective_IsEffective = 1 )
--                    LEFT JOIN [Base_Role_Trl] AS A2 ON ( A2.SysMLFlag = A3.Code )
--                                                       AND ( A1.[ID] = A2.[ID] )
--													   LEFT JOIN dbo.Base_UserOrg uo ON a.UserOrg=uo.ID
--													   LEFT JOIN dbo.Base_User u ON uo.[User]=u.ID
--													   LEFT JOIN dbo.Base_Organization o ON uo.Org=o.ID
--          WHERE     ( 
--		  --( A.[UserOrg] = (SELECT ID FROM Base_UserOrg t WHERE t.[User]=(SELECT id FROM dbo.Base_User WHERE name=@UserName) AND org=@Org) )
--                    --  AND 
--					  ( A1.[Type] != 1 )
--                    )
--        ) T
--		WHERE t.Effective_IsEffective=1
--		ORDER BY t.Name,t.Code,t.Role_Code

--		--SELECT * FROM Base_User