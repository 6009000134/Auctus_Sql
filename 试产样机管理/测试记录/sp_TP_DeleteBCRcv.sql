/*
删除测商务中心数据
*/
ALTER PROC sp_TP_DeleteBCRcv
(
@ID int
)
AS
BEGIN
	IF EXISTS (SELECT 1 FROM dbo.TP_RDRcv a WHERE a.ID=@ID AND a.Status!='0')
	BEGIN 
		SELECT '0'MsgType,'单据不是开立状态，不可删除！'Msg		
	END 
	ELSE 
		DELETE FROM dbo.TP_BCRcv  WHERE id=@ID
		DELETE FROM dbo.TP_BCRcvDetail WHERE RcvID=@ID
		SELECT '1'MsgType,'删除成功'Msg
	END 
END 