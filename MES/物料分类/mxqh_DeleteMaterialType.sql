/*
验证分类以及子分类是否有被引用，若有则不删除。
反之,删除分类以及分分类下的所有子分类
*/
ALTER PROC mxqh_DeleteMaterialType
(
@ID INT
)
AS
BEGIN

DECLARE @Result VARCHAR(4)

IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#tempMT') AND TYPE='U')
BEGIN
	DROP TABLE #tempMT
END 

;WITH data1 AS
(
SELECT a.ID,a.TypeCode,a.TypeName,a.PID FROM dbo.baMaterialType a WHERE a.ID=@ID
UNION ALL
SELECT a.ID,a.TypeCode,a.TypeName,a.PID FROM dbo.baMaterialType a INNER JOIN data1 b ON a.PID=b.ID
)
SELECT * INTO #tempMT FROM data1 a 

--判断是否有分类被引用
IF EXISTS(SELECT a.ID FROM dbo.baMaterial a INNER JOIN #tempMT b ON a.MaterialTypeID=b.ID)
BEGIN
	SELECT '0' MsgType,'分类被引用，不可删除！'Msg
END 
ELSE--未被引用
BEGIN
	DELETE FROM dbo.baMaterialType WHERE dbo.baMaterialType.ID IN (SELECT ID FROM #tempMT)
	SELECT '1' MsgType,'删除成功！'Msg
END 



END 