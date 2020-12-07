--设备
CREATE TABLE mxqh_Equipment
(
ID INT PRIMARY KEY IDENTITY(1,1),
CreateBy NVARCHAR(50),
CreateDate DATETIME DEFAULT(GETDATE()),
ModifyBy NVARCHAR(50),
ModifyDate DATETIME DEFAULT(GETDATE()),
Code NVARCHAR(300),--设备编码
Name NVARCHAR(300),--设备名称
TypeID INT,
TypeCode NVARCHAR(300),--设备类型编码
TypeName NVARCHAR(300),--设备类型名称
[Type] NVARCHAR(300),--型号
CheckUOM INT,--点检单位
UpperLimit DECIMAL(18,4),--上限
LowerLimit DECIMAL(18,4),--下限
Remark NVARCHAR(600)
)
