/*
SELECT * INTO #TempTable8 FROM dbo.Auctus_FullSetCheckResult8 a WHERE a.CopyDate>'2022-12-05'
DELETE FROM dbo.Auctus_FullSetCheckResult8  WHERE CopyDate>'2022-12-05'
EXEC dbo.sp_Auctus_BackUp_FullSetCheckResult8
*/

/*
DELETE FROM dbo.Auctus_FullSetCheckResult8  WHERE CopyDate>'2022-12-05'
INSERT INTO Auctus_FullSetCheckResult8 SELECT * FROM #TempTable8
*/
