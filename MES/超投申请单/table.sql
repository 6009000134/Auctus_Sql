/*
��Ͷ���뵥
*/
Create TABLE mxqh_OverInput
(
ID INT PRIMARY KEY IDENTITY(1,1),
CreateBy VARCHAR(100),--������
CreateDate DATETIME,
ModifyBy VARCHAR(100),
ModifyDate DATETIME,
DocNo VARCHAR(100) NOT null,--��Ͷ����
WorkOrderID INT NOT null,
WorkOrder VARCHAR(100) NOT null,--��������
OverInputQty INT NOT null,--��Ͷ����
OverInputedQty INT NOT null,
Status INT NOT null,--����״̬
Reason NVARCHAR(1000),--��Ͷԭ��
OAFlowID VARCHAR(100)
--SELECT * FROM dbo.TP_RDRcv
)
EXECUTE sp_addextendedproperty 'MS_Description','��Ͷ����','user','dbo','table','mxqh_OverInput','column','OverInputQty';
EXECUTE sp_addextendedproperty 'MS_Description','�ѳ�Ͷ����','user','dbo','table','mxqh_OverInput','column','OverInputedQty';
EXECUTE sp_addextendedproperty 'MS_Description','0\1\2 ����������С������','user','dbo','table','mxqh_OverInput','column','Status';
EXECUTE sp_addextendedproperty 'MS_Description','��Ͷԭ��','user','dbo','table','mxqh_OverInput','column','Reason';
EXECUTE sp_addextendedproperty 'MS_Description','OA����ID','user','dbo','table','mxqh_OverInput','column','OAFlowID';



