/*
SELECT * INTO #TempTable8 FROM dbo.Auctus_FullSetCheckResult8 a WHERE a.CopyDate>'2022-11-14'
DELETE FROM dbo.Auctus_FullSetCheckResult8  WHERE CopyDate>'2022-11-14'
EXEC dbo.sp_Auctus_BackUp_FullSetCheckResult8
*/

/*
DELETE FROM dbo.Auctus_FullSetCheckResult8  WHERE CopyDate>'2022-11-14'
INSERT INTO Auctus_FullSetCheckResult8 SELECT * FROM #TempTable8
*/
