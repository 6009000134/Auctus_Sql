--�豸
CREATE TABLE mxqh_Equipment
(
ID INT PRIMARY KEY IDENTITY(1,1),
CreateBy NVARCHAR(50),
CreateDate DATETIME DEFAULT(GETDATE()),
ModifyBy NVARCHAR(50),
ModifyDate DATETIME DEFAULT(GETDATE()),
Code NVARCHAR(300),--�豸����
Name NVARCHAR(300),--�豸����
TypeID INT,
TypeCode NVARCHAR(300),--�豸���ͱ���
TypeName NVARCHAR(300),--�豸��������
[Type] NVARCHAR(300),--�ͺ�
CheckUOM INT,--��쵥λ
UpperLimit DECIMAL(18,4),--����
LowerLimit DECIMAL(18,4),--����
Remark NVARCHAR(600)
)
