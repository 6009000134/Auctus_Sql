--��������
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
IsCheck INT,--�Ƿ�������Ʒ
IsSopReady INT,--SOP�Ƿ�����
Remark NVARCHAR(500)
)

--�׼�¼��
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
