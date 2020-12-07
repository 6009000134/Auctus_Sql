 /*
 ×Öµä±í
 */
 CREATE TABLE mxqh_Base_Dic
 (
 ID INT PRIMARY KEY IDENTITY(1,1),
 CreateBy NVARCHAR(40),
 CreateDate DATETIME,
 ModifyBy NVARCHAR(40),
 ModifyDate DATETIME,
 Code VARCHAR(50),
 Name NVARCHAR(50),
 TypeCode NVARCHAR(50),
 TypeName NVARCHAR(50)
 )