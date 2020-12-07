--SELECT * FROM dbo.mxqh_MoReleaseDtl

--SELECT * FROM dbo.opPlanExecutChild

--机身标签打印
CREATE TABLE mxqh_BodyLabelPrintLog
(
ID INT PRIMARY KEY IDENTITY(1,1),
CreateBy VARCHAR(30),
CreateDate DATETIME,
SNCode NVARCHAR(25)
)
