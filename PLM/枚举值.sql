--0枚举分类 2--枚举 1--枚举项
SELECT * FROM dbo.PS_Enum a WHERE a.Category=2 AND a.EnumValue='关联项目编码'	

--	INSERT INTO dbo.PS_Enum
--	        ( EnumId ,
--	          EnumValue ,
--	          EnumCode ,
--	          ParentId ,
--	          Category ,
--	          DisplaySeq ,
--	          IsDefault
--	        )
--SELECT NEWID(),WorkName,WorkCode,'567fe4b0-c651-492f-b957-2fe2073161b2',1,ROW_NUMBER()OVER(ORDER BY WorkCode)+
--(	SELECT MAX(DisplaySeq) FROM dbo.PS_Enum WHERE ParentId='567fe4b0-c651-492f-b957-2fe2073161b2'),0 
--FROM dbo.PJ_WorkPiece a LEFT JOIN (	SELECT * FROM dbo.PS_Enum WHERE ParentId='567fe4b0-c651-492f-b957-2fe2073161b2') b ON a.WorkCode=b.EnumCode 
--WHERE ProjectId='' AND WorkCode IN (
--'AU282',
--'AU258',
--'AU256',
--'AU281',
--'AU255','QZ008'
--) AND ISNULL(b.EnumId,'')=''




----0枚举分类 2--枚举 1--枚举项
--SELECT * FROM dbo.PS_Enum a WHERE a.Category=2 AND a.EnumValue='关联项目编码'	

--SELECT * FROM dbo.PS_Enum a 
--WHERE a.ParentId='d1c97829-e027-4316-9896-5dcc179b1531' 
--AND a.EnumCode IN ('PR011','PR013','PR014','PR015','PR016','PR017','PR018','','','')
--ORDER BY a.EnumCode
----INSERT INTO dbo.PS_Enum
----        ( EnumId ,
----          EnumValue ,
----          EnumCode ,
----          ParentId ,
----          Category ,
----          DisplaySeq ,
----          IsDefault
----        )
----SELECT NEWID(),WorkCode,WorkCode,'d1c97829-e027-4316-9896-5dcc179b1531',1,15+ROW_NUMBER()OVER(ORDER BY WorkCode),0 FROM dbo.PJ_WorkPiece WHERE ProjectId=''
----AND WorkCode NOT LIKE 'LS%'

----SELECT * FROM dbo.PJ_WorkPiece a WHERE 

----	INSERT INTO dbo.PS_Enum
----	        ( EnumId ,
----	          EnumValue ,
----	          EnumCode ,
----	          ParentId ,
----	          Category ,
----	          DisplaySeq ,
----	          IsDefault
----	        )
----SELECT NEWID(),WorkName,WorkCode,'567fe4b0-c651-492f-b957-2fe2073161b2',1,ROW_NUMBER()OVER(ORDER BY WorkCode)+
----(	SELECT MAX(DisplaySeq) FROM dbo.PS_Enum WHERE ParentId='567fe4b0-c651-492f-b957-2fe2073161b2'),0 
----FROM dbo.PJ_WorkPiece a LEFT JOIN (	SELECT * FROM dbo.PS_Enum WHERE ParentId='567fe4b0-c651-492f-b957-2fe2073161b2') b ON a.WorkCode=b.EnumCode 
----WHERE ProjectId='' AND WorkCode IN (
----'AU282',
----'AU258',
----'AU256',
----'AU281',
----'AU255','QZ008'
----) AND ISNULL(b.EnumId,'')=''
