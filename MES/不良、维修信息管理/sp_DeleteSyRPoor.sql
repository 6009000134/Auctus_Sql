/*
删除维修分类及下阶分类
*/
create  PROC sp_DeleteSyRPoor
(
@ID INT
)
AS
BEGIN
	DELETE FROM dbo.syRPoor WHERE ID=@ID
	DELETE FROM dbo.syRPoor WHERE PID=@ID
	SELECT '1'MsgType,'删除成功！' Msg							
END 
