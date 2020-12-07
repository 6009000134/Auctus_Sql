--开工单表
CREATE TABLE mxqh_MOStartInfo
(
ID INT PRIMARY KEY IDENTITY(1,1),
CreateBy VARCHAR(30),
CreateDate DATETIME,
ModifyBy VARCHAR(30),
ModifyDate DATETIME,
DocNo VARCHAR(50),
WorkOrderID INT,
StartQty INT,
IsCheck INT,--是否齐套料品
IsSopReady INT,--SOP是否完善
Remark NVARCHAR(500)
)

--首件录入
CREATE TABLE mxqh_FirstPiece
(
ID INT PRIMARY KEY IDENTITY(1,1),
CreateBy VARCHAR(30),
CreateDate DATETIME,
ModifyBy VARCHAR(30),
ModifyDate DATETIME,
WorkOrderID INT,
CheckDate DATETIME,
IsOk INT,
Remark VARCHAR(500)
)
