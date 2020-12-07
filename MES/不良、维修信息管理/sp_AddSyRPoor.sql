/*
添加维修信息
*/
ALTER PROC sp_AddSyRPoor
AS
BEGIN
--SELECT * FROM syRPoor ORDER BY TS desc
--SELECT * FROM #TempTable
IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#TempTable') AND TYPE='U')
BEGIN
	--是否存在大类
	IF EXISTS(SELECT 1 FROM #TempTable a ,dbo.syRPoor b WHERE a.TopType=b.Type)	
	BEGIN
		INSERT INTO dbo.syRPoor
		        ( TS ,Layer ,PID ,Code ,Name ,IsMonitor ,MaxPerHour ,MaxPerDay ,Description ,Type)
		SELECT GETDATE(),a.Layer,a.PID,a.Code,a.text,a.IsMonitor,1,1,NULL,a.TopType FROM #TempTable a		
	END 
	ELSE--不存在，代表新增大类和下阶类
    BEGIN
		INSERT INTO dbo.syRPoor
		        ( TS ,Layer ,PID ,Code ,Name ,IsMonitor ,MaxPerHour ,MaxPerDay ,Description ,Type)
		SELECT GETDATE(),(SELECT MAX(Layer)+1 FROM dbo.syRPoor),a.PID,a.Code,a.text,a.IsMonitor,1,1,NULL,a.TopType FROM #TempTable a
	END 
	--SELECT * FROM #temptable
	--SELECT GETDATE(),a.Layer+1,a.PID,a.Code,a.text,1,1,1,NULL,a.TopType FROM #TempTable a  
	SELECT '1'MsgType,'添加成功！' Msg							
END 
ELSE 
BEGIN 
	SELECT '0'MsgType,'添加失败！' Msg							
END 


END 