/*
删除测商务中心数据
*/
CREATE PROC sp_TP_DeleteBCRcv
(
@ID int
)
AS
BEGIN
	DELETE FROM dbo.TP_BCRcv  WHERE id=@ID
	DELETE FROM dbo.TP_BCRcvDetail WHERE RcvID=@ID
	SELECT '1'MsgType,'删除成功'Msg
END 