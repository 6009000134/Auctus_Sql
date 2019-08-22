/*
模具信息
*/
CREATE TABLE Mould
(
ID INT PRIMARY KEY IDENTITY(1,1),
CreateBy VARCHAR(20),
CreateDate DATETIME,
ModifyBy VARCHAR(20),
ModifyDate DATETIME,
Deleted CHAR(2),
Code VARCHAR(50),
Name NVARCHAR(300),
SPECS NVARCHAR(600),
HoleNum INT,--穴数
TotalNum INT,--寿命总次数
DailyCapacity INT,--日产能，默认22小时
DailyNum INT,--日模次=日产能/22
RemainNum INT,--剩余模次
Holder NVARCHAR(50),--使用委外商
Manufacturer NVARCHAR(50),--制造厂商
CycleTime DECIMAL(18,4),--成型周期(s)
ProductWeight DECIMAL(18,4),--产品重量（g）
NozzleWeight DECIMAL(18,4),--水口重量(g/pcs)
DealDate DATETIME,--购买日期
IsEffective BIT,--是否生效
EffectiveDate DATETIME,--启用日期
Remark NVARCHAR(800)
)

/*
模具料品关系
*/
CREATE TABLE Mould_ItemRelation
(
ID INT PRIMARY KEY IDENTITY(1,1),
CreateBy VARCHAR(20),
CreateDate DATETIME,
ModifyBy VARCHAR(20),
ModifyDate DATETIME,
Deleted CHAR(2) DEFAULT('0'),
MouldID INT,
MouldCode VARCHAR(50),
MouldName NVARCHAR(300),
MouldSPECS NVARCHAR(600),
ItemID BIGINT,
ItemCode VARCHAR(50),
ItemName NVARCHAR(300),
ItemSPECS NVARCHAR(600),
UnitOutput DECIMAL(18,4),
PoorRate DECIMAL(18,4),
EffectiveDate DATETIME,
DisableDate DATETIME,
Remark NVARCHAR(800)
)
/*
模具变更
*/
CREATE TABLE MouldModify
(
ID INT PRIMARY KEY IDENTITY(1,1),
CreateBy VARCHAR(20),
CreateDate DATETIME,
ModifyBy VARCHAR(20),
ModifyDate DATETIME,
DocNo VARCHAR(50),
Status INT,--0、1--开立、已审核
MouldID INT,--来自那个模具的变更
Code VARCHAR(50),
Name NVARCHAR(300),
SPECS NVARCHAR(600),
HoleNum INT,--穴数
TotalNum INT,--寿命总次数
DailyCapacity INT,--日产能，默认22小时
DailyNum INT,--日模次=日产能/22
RemainNum INT,--剩余模次
Holder NVARCHAR(50),--使用委外商
Manufacturer NVARCHAR(50),--制造厂商
CycleTime DECIMAL(18,4),--成型周期(s)
ProductWeight DECIMAL(18,4),--产品重量（g）
NozzleWeight DECIMAL(18,4),--水口重量(g/pcs)
DealDate DATETIME,--购买日期
IsEffective BIT,--是否生效
EffectiveDate DATETIME,--启用日期
Remark NVARCHAR(800)
)
--模具变更内容
CREATE TABLE MouldModifySeg
(
ID INT PRIMARY KEY IDENTITY(1,1),
CreateBy VARCHAR(20),
CreateDate DATETIME,
ModifyID INT,
ModifyBy VARCHAR(20),
ModifyDate DATETIME,
ModifySeg VARCHAR(100),--变更字段
DataType VARCHAR(30),
DataBeforeModify NVARCHAR(4000),--变更前内容	
DataAfterModify NVARCHAR(4000)--变更后内容
)


