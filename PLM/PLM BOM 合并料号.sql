--ALTER PROCEDURE sp_auctus_GetBomMergeData

--AS 

IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#FinalData') AND TYPE='U') BEGIN DROP TABLE #FinalData; END;

WITH
--最新产品 
LatestVersion AS 
(
	SELECT * FROM 
	(
		SELECT MaterialVerId, Code, Name, VerCode, IsFrozen, IsEffect, IsBlankOut,
		 ROW_NUMBER()OVER(PARTITION BY Code ORDER BY VerCode DESC)rowNum FROM dbo.MAT_MaterialVersion 
	) a
	WHERE IsEffect = 1 AND IsBlankOut = 0 AND a.IsFrozen = 0
	--WHERE a.rowNum =1
),
MergeData AS 
(
	SELECT [料号] AS OriCode, [合并成新的料号] TargetCode FROM dbo.ImportNewBom
),
MergeData2 AS 
(
	SELECT a.OriCode, b.MaterialVerId AS OriMateVerId, b.VerCode OriVerCode, a.TargetCode, c.MaterialVerId AS TargetVerId, c.VerCode AS TarVerCode
	FROM MergeData a 
		INNER JOIN LatestVersion b ON a.OriCode = b.Code
		INNER JOIN LatestVersion c ON a.TargetCode = c.Code
)
,BomData AS 
(
	SELECT a.RelationId, a.ParentVerId, b.Code AS ParentCode, b.Name AS ParentName, b.VerCode AS ParentVerCode,  a.ChildVerId, c.Code AS ChildCode, 
		c.Name AS ChildName, c.VerCode AS ChildVerCode, a.Radix, a.ChildCount, A.AssemblyPlace, a.DisplaySeq
	FROM dbo.MAT_MaterialRelation a 
		LEFT JOIN dbo.MAT_MaterialVersion b ON a.ParentVerId = b.MaterialVerId
		LEFT JOIN dbo.MAT_MaterialVersion c ON a.ChildVerId = c.MaterialVerId
		INNER JOIN LatestVersion d ON a.ParentVerId = d.MaterialVerId
	--WHERE b.IsFrozen = 0 AND b.IsBlankOut = 0
),
FinalData AS 
(
	SELECT a.RelationId, a.ParentVerId, a.ChildVerId, a.DisplaySeq,
		a.ParentCode, a.ParentVerCode, a.ChildCode, a.ChildVerCode, b.TargetCode, b.TargetVerId,--c.TargetCode,
		a.Radix, a.ChildCount, CASE WHEN A.AssemblyPlace = '' THEN NULL ELSE a.AssemblyPlace END AssemblyPlace,
		SUM(a.ChildCount)OVER(PARTITION BY a.ParentCode, b.TargetCode) AS NewChildCount,
		(SELECT COUNT(1) FROM dbo.MAT_Substitute s INNER JOIN dbo.MAT_MaterialVersion m ON s.SourceVerId = m.MaterialVerId
			INNER JOIN MergeData2 d ON s.TargetVerId = d.OriMateVerId
		WHERE s.ParentVerId = a.ParentVerId AND m.Code = a.ChildCode) IsSubChange,
		ROW_NUMBER()OVER(PARTITION BY a.ParentCode, b.TargetCode ORDER BY (CASE WHEN a.ChildCode = b.TargetCode THEN 0 ELSE 1 END)) rowNum
	FROM BomData a 
		LEFT JOIN MergeData2 b ON a.ChildCode = b.OriCode
		--LEFT JOIN MergeData2 c ON a.ParentCode = c.OriCode
	--WHERE --(c.TargetCode IS NOT NULL OR b.TargetCode IS NOT NULL)
		--b.TargetCode IS NOT NULL
)
SELECT * INTO #FinalData FROM FinalData a WHERE a.TargetCode IS NOT NULL OR a.IsSubChange > 0;

;WITH

	BomData AS 
	(
		SELECT a.RelationId, a.ParentVerId, a.ChildVerId, a.ParentCode, a.ParentVerCode, a.ChildCode, a.ChildVerCode, a.TargetCode, a.TargetVerId,
				a.Radix, a.ChildCount, A.AssemblyPlace, a.NewChildCount, a.IsSubChange, a.DisplaySeq,
			   ISNULL(STUFF((SELECT ',' + b.AssemblyPlace FROM #FinalData b WHERE b.ParentVerId = a.ParentVerId AND b.TargetCode = a.TargetCode ORDER BY b.rowNum FOR XML PATH('')), 1, 1, ''), '') NewAssPlace,
			a.rowNum
		FROM #FinalData a
	),
	FinalData AS 
	(
		SELECT *, CASE WHEN a.ChildCode != a.TargetCode OR a.ChildCount != a.NewChildCount 
			OR a.AssemblyPlace != a.NewAssPlace OR a.rowNum > 1 OR a.IsSubChange > 0 THEN 1 ELSE 0 END IsNeedChange 
		FROM BomData a
	)
	SELECT * FROM FinalData a --WHERE a.TargetCode IS NULL
	--WHERE a.ParentCode = '202010683' --AND a.IsNeedChange = 1


	--SELECT * FROM FinalData a WHERE a.ParentCode = '202010683' --AND a.ChildCode = '307011728'