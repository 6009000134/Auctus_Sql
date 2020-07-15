/*
超投申请单
*/
Create TABLE mxqh_OverInput
(
ID INT PRIMARY KEY IDENTITY(1,1),
CreateBy VARCHAR(100),--创建人
CreateDate DATETIME,
ModifyBy VARCHAR(100),
ModifyDate DATETIME,
DocNo VARCHAR(100) NOT null,--超投单号
WorkOrderID INT NOT null,
WorkOrder VARCHAR(100) NOT null,--工单单号
OverInputQty INT NOT null,--超投数量
OverInputedQty INT NOT null,
Status INT NOT null,--单据状态
Reason NVARCHAR(1000),--超投原因
OAFlowID VARCHAR(100)
--SELECT * FROM dbo.TP_RDRcv
)
EXECUTE sp_addextendedproperty 'MS_Description','超投数量','user','dbo','table','mxqh_OverInput','column','OverInputQty';
EXECUTE sp_addextendedproperty 'MS_Description','已超投数量','user','dbo','table','mxqh_OverInput','column','OverInputedQty';
EXECUTE sp_addextendedproperty 'MS_Description','0\1\2 开立、审核中、已审核','user','dbo','table','mxqh_OverInput','column','Status';
EXECUTE sp_addextendedproperty 'MS_Description','超投原因','user','dbo','table','mxqh_OverInput','column','Reason';
EXECUTE sp_addextendedproperty 'MS_Description','OA流程ID','user','dbo','table','mxqh_OverInput','column','OAFlowID';



