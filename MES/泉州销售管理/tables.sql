--SELECT * FROM dbo.qz_SaleAgent
--SELECT * FROM dbo.qz_SaleDeliver
--SELECT * FROM dbo.qz_SaleDeliverDtl

/*
Ȫ�����۴�����
*/
CREATE TABLE qz_SOAgent
(
ID INT PRIMARY KEY IDENTITY(1,1),
CreateBy NVARCHAR(50),
CreateDate DATETIME DEFAULT(GETDATE()),
ModifyBy NVARCHAR(50),
ModifyDate DATETIME,
Code NVARCHAR(50),--����
Name NVARCHAR(300),--����
Contact NVARCHAR(50),--��ϵ��
ContactNumber NVARCHAR(200),--�绰/�ֻ�����
Remark NVARCHAR(500)
)
/*
Ȫ�����۱�
*/
CREATE TABLE qz_SO
(
ID INT PRIMARY KEY IDENTITY(1,1),
CreateBy NVARCHAR(50),
CreateDate DATETIME DEFAULT(GETDATE()),
ModifyBy NVARCHAR(50),
ModifyDate DATETIME,
DocNo VARCHAR(100),--����
SOAgentID INT,--������
SOAgentCode NVARCHAR(50),
SOAgentName NVARCHAR(300),
MaterialID INT,--�Ϻ�
MaterialCode NVARCHAR(50),
MaterialName NVARCHAR(300),
Quantity INT,--��������
Status INT--����״̬
)
/*
Ȫ��������ϸ��
*/
CREATE TABLE qz_SODetail
(
ID INT PRIMARY KEY IDENTITY(1,1),
CreateBy NVARCHAR(50),
CreateDate DATETIME DEFAULT(GETDATE()),
ModifyBy NVARCHAR(50),
ModifyDate DATETIME,
SOID INT,
PackageNO VARCHAR(50),--���
BSN NVARCHAR(100)--�ڿ���
)


