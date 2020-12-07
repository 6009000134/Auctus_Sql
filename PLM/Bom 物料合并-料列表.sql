--CREATE PROCEDURE sp_auctus_MergeMate

--AS 

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
	SELECT a.OriCode, b.MaterialVerId AS OriVerId, b.VerCode OriVerCode, a.TargetCode, c.MaterialVerId AS TargetVerId, c.VerCode AS TarVerCode
	FROM MergeData a 
		INNER JOIN LatestVersion b ON a.OriCode = b.Code
		INNER JOIN LatestVersion c ON a.TargetCode = c.Code
)
SELECT * FROM MergeData2 a WHERE a.OriCode = '307010101'