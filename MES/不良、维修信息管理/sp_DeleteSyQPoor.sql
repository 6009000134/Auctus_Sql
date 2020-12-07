/*
删除不良分类及下阶分类
*/
ALTER  PROC sp_DeleteSyQPoor
(
@ID INT
)
AS
BEGIN
	DELETE FROM dbo.syQPoor WHERE ID=@ID
	DELETE FROM dbo.syQPoor WHERE PID=@ID
	SELECT '1'MsgType,'删除成功！' Msg							
END 
