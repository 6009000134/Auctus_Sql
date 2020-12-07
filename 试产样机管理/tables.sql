/*
--�﷨
execute sp_addextendedproperty 'MS_Description','�ֶα�ע��Ϣ','user','dbo','table','�ֶ������ı���','column','���ע�͵��ֶ���';
*/
/*
1���жϲ��������Ƿ����깤
2���жϲ��������Ƿ�������������
*/
CREATE TABLE TP_TestRecord
(
ID INT PRIMARY KEY IDENTITY(1,1),
CreateBy VARCHAR(100),
CreateDate DATETIME DEFAULT(GETDATE()),
ModifyBy VARCHAR(100),
ModifyDate DATETIME,
DocNo VARCHAR(50),
TestedBy VARCHAR(100),--������
TestedDate DATETIME,
Status INT,
Remark NVARCHAR(2000)
)
/*
������ϸ��
1��У���Ƿ��Ѿ�ɨ���

*/
CREATE TABLE TP_TestDetail
(
ID INT PRIMARY KEY IDENTITY(1,1),
CreateBy VARCHAR(100),
CreateDate DATETIME DEFAULT(GETDATE()),
ModifyBy VARCHAR(100),
ModifyDate DATETIME,
TestRecordID INT,
SNCode VARCHAR(100),
ProduceBy BIT DEFAULT(1),--1/0 ����/����
MaterialID INT,
MaterialCode VARCHAR(100),
MaterialName NVARCHAR(600),
IsPass BIT,--0/1  δͨ��/ͨ��
Remark NVARCHAR(2000)
)
/*
������
*/
CREATE TABLE TP_TestFile
(
ID INT PRIMARY KEY IDENTITY(1,1),
CreateBy VARCHAR(100),
CreateDate DATETIME DEFAULT(GETDATE()),
TestRecordID INT,
FileUrl VARCHAR(500)
)


/*
�з�����
*/
CREATE TABLE TP_RDRcv
(
ID INT PRIMARY KEY IDENTITY(1,1),
CreateBy VARCHAR(100),
CreateDate DATETIME DEFAULT(GETDATE()),
ModifyBy VARCHAR(100),
ModifyDate DATETIME,
DocNo VARCHAR(50),
DocType VARCHAR(100),--�������ͣ���⡢�黹
Operator VARCHAR(100),--������
RcvDate DATETIME,
ProjectID VARCHAR(100),
ProjectCode VARCHAR(100),
ProjectName NVARCHAR(200),
ReturnDeptID INT,--�黹����
DeptCode VARCHAR(50),
DeptName VARCHAR(50),
Borrower VARCHAR(100),
CustomerID INT,
CustomerCode VARCHAR(50),
CustomerName VARCHAR(100),
Remark VARCHAR(2000)
)
/*
�з������ϸ��
*/
CREATE TABLE TP_RDRcvDetail
(
ID INT PRIMARY KEY IDENTITY(1,1),
CreateBy VARCHAR(100),
CreateDate DATETIME DEFAULT(GETDATE()),
ModifyBy VARCHAR(100),
ModifyDate DATETIME,
RcvID INT,
InternalCode VARCHAR(100),
SNCode VARCHAR(100),
MaterialID INT,
MaterialCode VARCHAR(50),
MaterialName NVARCHAR(600),
Status VARCHAR(10),--0\1\2 ���á�����������
Progress VARCHAR(10),
Remark VARCHAR(2000)
)



/*
�з������
*/
CREATE TABLE TP_RDShip
(
ID INT PRIMARY KEY IDENTITY(1,1),
CreateBy VARCHAR(100),
CreateDate DATETIME DEFAULT(GETDATE()),
ModifyBy VARCHAR(100),
ModifyDate DATETIME,
DocNo VARCHAR(50),
DocType VARCHAR(100),--��������
Operator VARCHAR(50),
ReturnDeptID INT,--�黹����
DeptCode VARCHAR(50),
DeptName VARCHAR(50),
Borrower VARCHAR(100),
CustomerID INT,
CustomerCode VARCHAR(50),
CustomerName VARCHAR(100),
DeliverDate DATETIME,--��������
PlanReturnDate DATETIME,--�ƻ��黹����
Remark NVARCHAR(2000)
)

/*
�з�������ϸ��
*/
CREATE TABLE TP_RDShipDetail
(
ID INT PRIMARY KEY IDENTITY(1,1),
CreateBy VARCHAR(100),
CreateDate DATETIME DEFAULT(GETDATE()),
ModifyBy VARCHAR(100),
ModifyDate DATETIME,
ShipID INT,
InternalCode VARCHAR(100),
SNCode VARCHAR(100),
MaterialID INT,
MaterialCode VARCHAR(50),
MaterialName NVARCHAR(600),
Status VARCHAR(10),--0\1\2 ���á�����������
Progress VARCHAR(10),
Remark VARCHAR(2000)
)



/*
�ֵ��
*/
CREATE TABLE [dbo].[TP_Dictionary]
(
[ID] [int] NOT NULL IDENTITY(1, 1) PRIMARY KEY,
[CreateBy] [nvarchar] (40) COLLATE Chinese_PRC_CI_AS NULL,
[CreateDate] [datetime] NULL DEFAULT (getdate()),
[ModifyBy] [nvarchar] (40) COLLATE Chinese_PRC_CI_AS NULL,
[ModifyDate] [datetime] NULL ,
[Code] [nvarchar] (300) COLLATE Chinese_PRC_CI_AS NULL,
[Name] [nvarchar] (300) COLLATE Chinese_PRC_CI_AS NULL,
[TypeCode] [nvarchar] (300) COLLATE Chinese_PRC_CI_AS NULL,
[TypeName] [nvarchar] (300) COLLATE Chinese_PRC_CI_AS NULL,
[IsActive] [int] NULL DEFAULT(1),
[OrderNo] [int] NULL DEFAULT(0),
Remark VARCHAR(MAX)
)



/*
��Ʒ��������
*/
CREATE TABLE TP_PCRcv
(
ID INT PRIMARY KEY IDENTITY(1,1),
CreateBy VARCHAR(100),
CreateDate DATETIME DEFAULT(GETDATE()),
ModifyBy VARCHAR(100),
ModifyDate DATETIME,
DocNo VARCHAR(50),
DocType VARCHAR(100),--�������ͣ���⡢�黹
Operator VARCHAR(100),--������
RcvDate DATETIME,
ProjectID VARCHAR(100),
ProjectCode VARCHAR(100),
ProjectName NVARCHAR(200),
ReturnDeptID INT,--�黹����
DeptCode VARCHAR(50),
DeptName VARCHAR(50),
Borrower VARCHAR(100),
CustomerID INT,
CustomerCode VARCHAR(50),
CustomerName VARCHAR(100),
Remark VARCHAR(2000)
)
/*
��Ʒ���������ϸ��
*/
CREATE TABLE TP_PCRcvDetail
(
ID INT PRIMARY KEY IDENTITY(1,1),
CreateBy VARCHAR(100),
CreateDate DATETIME DEFAULT(GETDATE()),
ModifyBy VARCHAR(100),
ModifyDate DATETIME,
RcvID INT,
InternalCode VARCHAR(100),
SNCode VARCHAR(100),
MaterialID INT,
MaterialCode VARCHAR(50),
MaterialName NVARCHAR(600),
Status VARCHAR(10),--0\1\2 ���á�����������
Progress VARCHAR(10),
SoftUpdateDate DATE,
Remark VARCHAR(2000)
)



/*
��Ʒ���ĳ����
*/
CREATE TABLE TP_PCShip
(
ID INT PRIMARY KEY IDENTITY(1,1),
CreateBy VARCHAR(100),
CreateDate DATETIME DEFAULT(GETDATE()),
ModifyBy VARCHAR(100),
ModifyDate DATETIME,
DocNo VARCHAR(50),
DocType VARCHAR(100),--��������
Operator VARCHAR(50),
ReturnDeptID INT,--�黹����
DeptCode VARCHAR(50),
DeptName VARCHAR(50),
Borrower VARCHAR(100),
CustomerID INT,
CustomerCode VARCHAR(50),
CustomerName VARCHAR(100),
DeliverDate DATETIME,--��������
PlanReturnDate DATETIME,--�ƻ��黹����
Remark NVARCHAR(2000)
)

/*
��Ʒ���ĳ�����ϸ��
*/
CREATE TABLE TP_PCShipDetail
(
ID INT PRIMARY KEY IDENTITY(1,1),
CreateBy VARCHAR(100),
CreateDate DATETIME DEFAULT(GETDATE()),
ModifyBy VARCHAR(100),
ModifyDate DATETIME,
ShipID INT,
InternalCode VARCHAR(100),
SNCode VARCHAR(100),
MaterialID INT,
MaterialCode VARCHAR(50),
MaterialName NVARCHAR(600),
Status VARCHAR(10),--0\1\2 ���á�����������
Progress VARCHAR(10),
SoftUpdateDate DATE,
Remark VARCHAR(2000)
)

/*
������������
*/
CREATE TABLE TP_BCRcv
(
ID INT PRIMARY KEY IDENTITY(1,1),
CreateBy VARCHAR(100),
CreateDate DATETIME DEFAULT(GETDATE()),
ModifyBy VARCHAR(100),
ModifyDate DATETIME,
DocNo VARCHAR(50),
DocType VARCHAR(100),--�������ͣ���⡢�黹
Operator VARCHAR(100),--������
RcvDate DATETIME,
ProjectID VARCHAR(100),
ProjectCode VARCHAR(100),
ProjectName NVARCHAR(200),
ReturnDeptID INT,--�黹����
DeptCode VARCHAR(50),
DeptName VARCHAR(50),
Borrower VARCHAR(100),
CustomerID INT,
CustomerCode VARCHAR(50),
CustomerName VARCHAR(100),
Remark VARCHAR(2000)
)
/*
�������������ϸ��
*/
CREATE TABLE TP_BCRcvDetail
(
ID INT PRIMARY KEY IDENTITY(1,1),
CreateBy VARCHAR(100),
CreateDate DATETIME DEFAULT(GETDATE()),
ModifyBy VARCHAR(100),
ModifyDate DATETIME,
RcvID INT,
InternalCode VARCHAR(100),
SNCode VARCHAR(100),
MaterialID INT,
MaterialCode VARCHAR(50),
MaterialName NVARCHAR(600),
Status VARCHAR(10),--0\1\2 ���á�����������
Progress VARCHAR(10),
TypeID INT,
TypeCode VARCHAR(20),
TypeName VARCHAR(20),
Remark VARCHAR(2000)
)




/*
�������ĳ����
*/
CREATE TABLE TP_BCShip
(
ID INT PRIMARY KEY IDENTITY(1,1),
CreateBy VARCHAR(100),
CreateDate DATETIME DEFAULT(GETDATE()),
ModifyBy VARCHAR(100),
ModifyDate DATETIME,
DocNo VARCHAR(50),
DocType VARCHAR(100),--��������
Operator VARCHAR(50),
ReturnDeptID INT,--�黹����
DeptCode VARCHAR(50),
DeptName VARCHAR(50),
Borrower VARCHAR(100),
CustomerID INT,
CustomerCode VARCHAR(50),
CustomerName VARCHAR(100),
DeliverDate DATETIME,--��������
PlanReturnDate DATETIME,--�ƻ��黹����
Remark NVARCHAR(2000)
)

/*
�������ĳ�����ϸ��
*/
CREATE TABLE TP_BCShipDetail
(
ID INT PRIMARY KEY IDENTITY(1,1),
CreateBy VARCHAR(100),
CreateDate DATETIME DEFAULT(GETDATE()),
ModifyBy VARCHAR(100),
ModifyDate DATETIME,
ShipID INT,
InternalCode VARCHAR(100),
SNCode VARCHAR(100),
MaterialID INT,
MaterialCode VARCHAR(50),
MaterialName NVARCHAR(600),
Status VARCHAR(10),--0\1\2 ���á�����������
Progress VARCHAR(10),
TypeID INT,
TypeCode VARCHAR(20),
TypeName VARCHAR(20),
Remark VARCHAR(2000)
)