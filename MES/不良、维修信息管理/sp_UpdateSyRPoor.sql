/*
添加维修信息
*/
ALTER   PROC sp_UpdateSyRPoor
AS
BEGIN

IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#TempTable') AND TYPE='U')
BEGIN		
	UPDATE dbo.syRPoor SET Code=a.Code,Name=a.text,Layer=a.Layer,IsMonitor=a.IsMonitor FROM #TempTable a WHERE a.ID=dbo.syRPoor.ID
	SELECT '1'MsgType,'修改成功！' Msg							
END 
	SELECT '0'MsgType,'修改失败！' Msg							

END 