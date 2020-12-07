--���������
CREATE TABLE mxqh_QualityProperty
(
ID INT PRIMARY key IDENTITY(1,1),
CreateBy  VARCHAR(30),
CreateDate DATETIME,
ModifyBy VARCHAR(30),
ModifyDate DATETIME,
PID INT,
Code VARCHAR(30),
text NVARCHAR(30),
OrderNo INT
)

--�������ģ��
CREATE TABLE mxqh_QualityTemplate
(
ID INT PRIMARY key IDENTITY(1,1),
CreateBy  VARCHAR(30),
CreateDate DATETIME,
ModifyBy VARCHAR(30),
ModifyDate DATETIME,
Code NVARCHAR(255),
Name NVARCHAR(255),
OrderNo int
)

--ģ��-���ά�����ϵ��
CREATE TABLE mxqh_QualityTPRelation
(
ID INT PRIMARY key IDENTITY(1,1),
CreateBy  VARCHAR(30),
CreateDate DATETIME,
ModifyBy VARCHAR(30),
ModifyDate DATETIME,
TemplateID INT,
TemplateCode NVARCHAR(255),
TemplateName NVARCHAR(255),
PropertyID INT,
PropertyCode VARCHAR(255),
PropertyName NVARCHAR(255),
OrderNo INT
)