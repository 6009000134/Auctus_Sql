--ÆëÌ×»ã×Ü½á¹û
CREATE TABLE Auctus_FullSetCheckSummary
(
MRPCategory NVARCHAR(30),
Buyer NVARCHAR(20),
MCName NVARCHAR(20),
Code NVARCHAR(50),
Name NVARCHAR(300),
SPECS NVARCHAR(600),
W0 INT,
W1 INT,
W2 INT,
W3 INT,
W4 INT,
W5 INT,
W6 INT,
W7 INT,
W8 INT,
WhQty INT,
WhAvailiableAmount INT,
CopyDate DATETIME
)
--DROP TABLE Auctus_FullSetCheckSummary

--INSERT INTO Auctus_FullSetCheckSummary
--SELECT a.MRPCategory,a.Buyer,a.MCName,a.Code,a.Name,a.SPEC,ISNULL(a.w0,0), ISNULL(a.w1,0),ISNULL(a.w2,0),ISNULL(a.w3,0),ISNULL(a.w4,0),ISNULL(a.w5,0),ISNULL(a.w6,0),ISNULL(a.w7,0),ISNULL(a.w8,0)
--,a.WhQty,a.WhAvailiableAmount,GETDATE()
--FROM #tempW8 a
--UNION ALL
--SELECT a.MRPCategory,a.Operators,'',a.Code,a.Name,a.SPEC,ISNULL(a.w0,0), ISNULL(a.w1,0),ISNULL(a.w2,0),ISNULL(a.w3,0),ISNULL(a.w4,0),ISNULL(a.w5,0),ISNULL(a.w6,0),ISNULL(a.w7,0),ISNULL(a.w8,0)
--,a.WhQty,a.WhAvailiableAmount,GETDATE()
--FROM #tempMW8 a
