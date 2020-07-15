/*
修改超投单
1、开立单据才允许修改
*/
ALTER PROC sp_UpdateOverInput
AS
BEGIN
	IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#TempTable') AND TYPE='U')
	BEGIN
		IF EXISTS(SELECT 1 FROM dbo.mxqh_OverInput a INNER JOIN #TempTable b ON a.ID=b.ID AND a.Status<>0)
		BEGIN--开立单据才允许修改
			SELECT '0'MsgType,'单据不是开立状态，不允许修改！'Msg        
		END 
		ELSE
        BEGIN
        	UPDATE dbo.mxqh_OverInput SET OverInputQty=a.OverInputQty,Reason=a.Reason,ModifyBy=a.ModifyBy,ModifyDate=getdate()
			FROM #TempTable a WHERE a.id=dbo.mxqh_OverInput.ID
			SELECT '1'MsgType,'修改成功！'Msg
		END 		
	END 
	ELSE
		SELECT '0'MsgType,'修改失败！'Msg
END 

