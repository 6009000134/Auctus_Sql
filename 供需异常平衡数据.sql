--供需平衡异常数据
CREATE TABLE Auctus_SupplyAndDemandReport
(
PlanCode VARCHAR(100),--计划编码
Version VARCHAR(50),--计划版本
ItemMaster BIGINT,
Code VARCHAR(50),
Name NVARCHAR(255),
SPEC NVARCHAR(300),
DocNo VARCHAR(50),
DemandCode VARCHAR(50),
DSType NVARCHAR(50),--需求供应形态
DocType NVARCHAR(50),--单据类型
NetQty DECIMAL(18,4),--净数量
TradeBaseQty DECIMAL(18,4),--交易数量
Remark NVARCHAR(MAX)
)