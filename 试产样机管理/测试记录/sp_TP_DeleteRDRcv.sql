/*
删除测试数据
*/
alter PROC sp_TP_DeleteRDRcv
(
@ID int
)
AS
BEGIN
	DELETE FROM dbo.TP_RDRcv  WHERE id=@ID
	DELETE FROM dbo.TP_RDRcvDetail WHERE RcvID=@ID
	SELECT '1'MsgType,'删除成功'Msg
END 