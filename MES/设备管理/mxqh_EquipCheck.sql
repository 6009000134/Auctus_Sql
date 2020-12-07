
CREATE TABLE mxqh_EquipCheck
(
ID int PRIMARY KEY IDENTITY(1,1),
CreateBy nvarchar(30),
CreateDate datetime,
ModifyBy nvarchar(30),
ModifyDate DATETIME,
CheckDate DATETIME,
Duration INT,
WorkOrderID INT,
EquipID INT,
Record DECIMAL(18,4),
Remark NVARCHAR(300)
)