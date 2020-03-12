/*
完工报告表
*/
CREATE TABLE mxqh_CompleteRpt
(
ID INT PRIMARY KEY IDENTITY(1,1),
CreateBy NVARCHAR(30),
CreateDate DATETIME,
ModifyBy NVARCHAR(30),
ModifyDate DATETIME,
DocNo VARCHAR(30),
DocType BIGINT,
DocTypeCode VARCHAR(30),
DocTypeName NVARCHAR(30),
Status INT,
MaterialID INT,
MaterialCode VARCHAR(30),
MaterialName NVARCHAR(600),
WorkOrderID INT,
WorkOrder VARCHAR(30),
CompleteDate DATETIME,
CompleteQty INT,
ActualRcvQty INT
)

--SELECT * FROM dbo.mxqh_plAssemblyPlanDetail