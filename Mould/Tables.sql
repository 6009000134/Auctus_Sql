/*
ģ����Ϣ
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
HoleNum INT,--Ѩ��
TotalNum INT,--�����ܴ���
DailyCapacity INT,--�ղ��ܣ�Ĭ��22Сʱ
DailyNum INT,--��ģ��=�ղ���/22
RemainNum INT,--ʣ��ģ��
Holder NVARCHAR(50),--ʹ��ί����
Manufacturer NVARCHAR(50),--���쳧��
CycleTime DECIMAL(18,4),--��������(s)
ProductWeight DECIMAL(18,4),--��Ʒ������g��
NozzleWeight DECIMAL(18,4),--ˮ������(g/pcs)
DealDate DATETIME,--��������
IsEffective BIT,--�Ƿ���Ч
EffectiveDate DATETIME,--��������
Remark NVARCHAR(800)
)

/*
ģ����Ʒ��ϵ
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
ģ�߱��
*/
CREATE TABLE MouldModify
(
ID INT PRIMARY KEY IDENTITY(1,1),
CreateBy VARCHAR(20),
CreateDate DATETIME,
ModifyBy VARCHAR(20),
ModifyDate DATETIME,
DocNo VARCHAR(50),
Status INT,--0��1--�����������
MouldID INT,--�����Ǹ�ģ�ߵı��
Code VARCHAR(50),
Name NVARCHAR(300),
SPECS NVARCHAR(600),
HoleNum INT,--Ѩ��
TotalNum INT,--�����ܴ���
DailyCapacity INT,--�ղ��ܣ�Ĭ��22Сʱ
DailyNum INT,--��ģ��=�ղ���/22
RemainNum INT,--ʣ��ģ��
Holder NVARCHAR(50),--ʹ��ί����
Manufacturer NVARCHAR(50),--���쳧��
CycleTime DECIMAL(18,4),--��������(s)
ProductWeight DECIMAL(18,4),--��Ʒ������g��
NozzleWeight DECIMAL(18,4),--ˮ������(g/pcs)
DealDate DATETIME,--��������
IsEffective BIT,--�Ƿ���Ч
EffectiveDate DATETIME,--��������
Remark NVARCHAR(800)
)
--ģ�߱������
CREATE TABLE MouldModifySeg
(
ID INT PRIMARY KEY IDENTITY(1,1),
CreateBy VARCHAR(20),
CreateDate DATETIME,
ModifyID INT,
ModifyBy VARCHAR(20),
ModifyDate DATETIME,
ModifySeg VARCHAR(100),--����ֶ�
DataType VARCHAR(30),
DataBeforeModify NVARCHAR(4000),--���ǰ����	
DataAfterModify NVARCHAR(4000)--���������
)


