/*
--语法
execute sp_addextendedproperty 'MS_Description','字段备注信息','user','dbo','table','字段所属的表名','column','添加注释的字段名';
*/
/*
1、判断测试样机是否已完工
2、判断测试样机是否被其他单据引用
*/
CREATE TABLE TP_TestRecord
(
ID INT PRIMARY KEY IDENTITY(1,1),
CreateBy VARCHAR(100),
CreateDate DATETIME DEFAULT(GETDATE()),
ModifyBy VARCHAR(100),
ModifyDate DATETIME,
DocNo VARCHAR(50),
TestedBy VARCHAR(100),--测试人
TestedDate DATETIME,
Status INT,
Remark NVARCHAR(2000)
)
/*
测试明细表
1、校验是否已经扫描过

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
ProduceBy BIT DEFAULT(1),--1/0 工厂/自制
MaterialID INT,
MaterialCode VARCHAR(100),
MaterialName NVARCHAR(600),
IsPass BIT,--0/1  未通过/通过
Remark NVARCHAR(2000)
)
/*
附件表
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
研发入库表
*/
CREATE TABLE TP_RDRcv
(
ID INT PRIMARY KEY IDENTITY(1,1),
CreateBy VARCHAR(100),
CreateDate DATETIME DEFAULT(GETDATE()),
ModifyBy VARCHAR(100),
ModifyDate DATETIME,
DocNo VARCHAR(50),
DocType VARCHAR(100),--单据类型：入库、归还
Operator VARCHAR(100),--操作人
RcvDate DATETIME,
ProjectID VARCHAR(100),
ProjectCode VARCHAR(100),
ProjectName NVARCHAR(200),
ReturnDeptID INT,--归还部门
DeptCode VARCHAR(50),
DeptName VARCHAR(50),
Borrower VARCHAR(100),
CustomerID INT,
CustomerCode VARCHAR(50),
CustomerName VARCHAR(100),
Remark VARCHAR(2000)
)
/*
研发入库明细表
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
Status VARCHAR(10),--0\1\2 良好、不良、报废
Progress VARCHAR(10),
Remark VARCHAR(2000)
)



/*
研发出库表
*/
CREATE TABLE TP_RDShip
(
ID INT PRIMARY KEY IDENTITY(1,1),
CreateBy VARCHAR(100),
CreateDate DATETIME DEFAULT(GETDATE()),
ModifyBy VARCHAR(100),
ModifyDate DATETIME,
DocNo VARCHAR(50),
DocType VARCHAR(100),--单据类型
Operator VARCHAR(50),
ReturnDeptID INT,--归还部门
DeptCode VARCHAR(50),
DeptName VARCHAR(50),
Borrower VARCHAR(100),
CustomerID INT,
CustomerCode VARCHAR(50),
CustomerName VARCHAR(100),
DeliverDate DATETIME,--出库日期
PlanReturnDate DATETIME,--计划归还日期
Remark NVARCHAR(2000)
)

/*
研发出库明细表
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
Status VARCHAR(10),--0\1\2 良好、不良、报废
Progress VARCHAR(10),
Remark VARCHAR(2000)
)



/*
字典表
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
产品中心入库表
*/
CREATE TABLE TP_PCRcv
(
ID INT PRIMARY KEY IDENTITY(1,1),
CreateBy VARCHAR(100),
CreateDate DATETIME DEFAULT(GETDATE()),
ModifyBy VARCHAR(100),
ModifyDate DATETIME,
DocNo VARCHAR(50),
DocType VARCHAR(100),--单据类型：入库、归还
Operator VARCHAR(100),--操作人
RcvDate DATETIME,
ProjectID VARCHAR(100),
ProjectCode VARCHAR(100),
ProjectName NVARCHAR(200),
ReturnDeptID INT,--归还部门
DeptCode VARCHAR(50),
DeptName VARCHAR(50),
Borrower VARCHAR(100),
CustomerID INT,
CustomerCode VARCHAR(50),
CustomerName VARCHAR(100),
Remark VARCHAR(2000)
)
/*
产品中心入库明细表
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
Status VARCHAR(10),--0\1\2 良好、不良、报废
Progress VARCHAR(10),
SoftUpdateDate DATE,
Remark VARCHAR(2000)
)



/*
产品中心出库表
*/
CREATE TABLE TP_PCShip
(
ID INT PRIMARY KEY IDENTITY(1,1),
CreateBy VARCHAR(100),
CreateDate DATETIME DEFAULT(GETDATE()),
ModifyBy VARCHAR(100),
ModifyDate DATETIME,
DocNo VARCHAR(50),
DocType VARCHAR(100),--单据类型
Operator VARCHAR(50),
ReturnDeptID INT,--归还部门
DeptCode VARCHAR(50),
DeptName VARCHAR(50),
Borrower VARCHAR(100),
CustomerID INT,
CustomerCode VARCHAR(50),
CustomerName VARCHAR(100),
DeliverDate DATETIME,--出库日期
PlanReturnDate DATETIME,--计划归还日期
Remark NVARCHAR(2000)
)

/*
产品中心出库明细表
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
Status VARCHAR(10),--0\1\2 良好、不良、报废
Progress VARCHAR(10),
SoftUpdateDate DATE,
Remark VARCHAR(2000)
)

/*
商务中心入库表
*/
CREATE TABLE TP_BCRcv
(
ID INT PRIMARY KEY IDENTITY(1,1),
CreateBy VARCHAR(100),
CreateDate DATETIME DEFAULT(GETDATE()),
ModifyBy VARCHAR(100),
ModifyDate DATETIME,
DocNo VARCHAR(50),
DocType VARCHAR(100),--单据类型：入库、归还
Operator VARCHAR(100),--操作人
RcvDate DATETIME,
ProjectID VARCHAR(100),
ProjectCode VARCHAR(100),
ProjectName NVARCHAR(200),
ReturnDeptID INT,--归还部门
DeptCode VARCHAR(50),
DeptName VARCHAR(50),
Borrower VARCHAR(100),
CustomerID INT,
CustomerCode VARCHAR(50),
CustomerName VARCHAR(100),
Remark VARCHAR(2000)
)
/*
商务中心入库明细表
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
Status VARCHAR(10),--0\1\2 良好、不良、报废
Progress VARCHAR(10),
TypeID INT,
TypeCode VARCHAR(20),
TypeName VARCHAR(20),
Remark VARCHAR(2000)
)




/*
商务中心出库表
*/
CREATE TABLE TP_BCShip
(
ID INT PRIMARY KEY IDENTITY(1,1),
CreateBy VARCHAR(100),
CreateDate DATETIME DEFAULT(GETDATE()),
ModifyBy VARCHAR(100),
ModifyDate DATETIME,
DocNo VARCHAR(50),
DocType VARCHAR(100),--单据类型
Operator VARCHAR(50),
ReturnDeptID INT,--归还部门
DeptCode VARCHAR(50),
DeptName VARCHAR(50),
Borrower VARCHAR(100),
CustomerID INT,
CustomerCode VARCHAR(50),
CustomerName VARCHAR(100),
DeliverDate DATETIME,--出库日期
PlanReturnDate DATETIME,--计划归还日期
Remark NVARCHAR(2000)
)

/*
商务中心出库明细表
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
Status VARCHAR(10),--0\1\2 良好、不良、报废
Progress VARCHAR(10),
TypeID INT,
TypeCode VARCHAR(20),
TypeName VARCHAR(20),
Remark VARCHAR(2000)
)