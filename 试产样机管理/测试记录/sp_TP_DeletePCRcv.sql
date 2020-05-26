/*
删除测产品中心数据
*/
CREATE PROC sp_TP_DeletePCRcv
(
@ID int
)
AS
BEGIN
	DELETE FROM dbo.TP_PCRcv  WHERE id=@ID
	DELETE FROM dbo.TP_PCRcvDetail WHERE RcvID=@ID
	SELECT '1'MsgType,'删除成功'Msg
END 