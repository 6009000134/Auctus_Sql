/*
导入标准BOM
*/
ALTER PROC [dbo].[sp_Auctus_ImportExcel]
AS
BEGIN
	IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#TempTable') AND TYPE='U')
	BEGIN
	DELETE FROM #TempTable WHERE Line='层次号'
		INSERT INTO dbo.Auctus_BOM (Line,Code, SPEC,Name,Num,Version,Cost,Weight,BOMUom,BaseNum,Waste,Position,Remark,createdate,No )
		SELECT Line,Code, SPEC,Name,Num,Version,Cost,Weight,BOMUom,BaseNum,Waste,Position,Remark,GETDATE(),ISNULL((SELECT MAX(ISNULL(No,1))+1 FROM auctus_Bom),1)
		FROM #TempTable 
	END
END 
--SELECT CONVERT(int,1)
--SELECT * FROM auctus_bom

--DELETE FROM dbo.auctus_bom



