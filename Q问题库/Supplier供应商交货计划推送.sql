/*
SELECT * INTO #TempTable8 FROM dbo.Auctus_FullSetCheckResult8 a WHERE a.CopyDate>'2023-01-31'
DELETE FROM dbo.Auctus_FullSetCheckResult8  WHERE CopyDate>'2023-01-31'
EXEC dbo.sp_Auctus_BackUp_FullSetCheckResult8
*/

/*
DELETE FROM dbo.Auctus_FullSetCheckResult8  WHERE CopyDate>'2023-01-31'
INSERT INTO Auctus_FullSetCheckResult8 SELECT * FROM #TempTable8
*/
/*
DECLARE @Date DATE=GETDATE()
SELECT * INTO #TempTable8 FROM dbo.Auctus_FullSetCheckResult8 a WHERE a.CopyDate>@Date
DELETE FROM dbo.Auctus_FullSetCheckResult8  WHERE CopyDate>@Date
EXEC dbo.sp_Auctus_BackUp_FullSetCheckResult8
*/

/*
DECLARE @Date DATE=GETDATE()
DELETE FROM dbo.Auctus_FullSetCheckResult8  WHERE CopyDate>@Date
INSERT INTO Auctus_FullSetCheckResult8 SELECT * FROM #TempTable8
*/