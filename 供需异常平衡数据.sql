--����ƽ���쳣����
CREATE TABLE Auctus_SupplyAndDemandReport
(
PlanCode VARCHAR(100),--�ƻ�����
Version VARCHAR(50),--�ƻ��汾
ItemMaster BIGINT,
Code VARCHAR(50),
Name NVARCHAR(255),
SPEC NVARCHAR(300),
DocNo VARCHAR(50),
DemandCode VARCHAR(50),
DSType NVARCHAR(50),--����Ӧ��̬
DocType NVARCHAR(50),--��������
NetQty DECIMAL(18,4),--������
TradeBaseQty DECIMAL(18,4),--��������
Remark NVARCHAR(MAX)
)