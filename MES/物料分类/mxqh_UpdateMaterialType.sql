/*
修改物料分类
*/
alter PROC mxqh_UpdateMaterialType
AS
BEGIN
	IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#TempTable') AND TYPE='U')
	BEGIN
		UPDATE dbo.baMaterialType SET TypeCode=a.TypeCode,TypeName=a.text FROM #TempTable a WHERE dbo.baMaterialType.ID=a.ID
		SELECT '1' MsgType,'修改成功！'Msg		
	END 
	ELSE
    BEGIN
		SELECT '0' MsgType,'修改失败！'Msg		
	END 
END 