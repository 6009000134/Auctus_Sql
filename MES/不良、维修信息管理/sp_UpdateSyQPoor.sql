
ALTER PROCEDURE [dbo].[sp_UpdateSyQPoor]
AS
BEGIN

IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#TempTable') AND TYPE='U')
BEGIN		
	UPDATE dbo.syQPoor SET Code=a.Code,Name=a.text,Layer=a.Layer,IsMonitor=a.IsMonitor FROM #TempTable a WHERE a.ID=dbo.syQPoor.ID
	--INSERT INTO dbo.syQPoor
	--		( TS ,
	--		  Layer ,
	--		  PID ,
	--		  Code ,
	--		  Name ,
	--		  IsMonitor ,
	--		  MaxPerHour ,
	--		  MaxPerDay ,
	--		  Description ,
	--		  Type
	--		)
	--SELECT GETDATE(),b.Layer+1,a.PID,a.Code,Name,1,1,1,NULL,b.Type FROM #TempTable a  ,dbo.syQPoor b  WHERE a.PID=b.ID

	SELECT '1'MsgType,'修改成功！' Msg						
END 
	SELECT '0'MsgType,'修改失败！' Msg							

END

