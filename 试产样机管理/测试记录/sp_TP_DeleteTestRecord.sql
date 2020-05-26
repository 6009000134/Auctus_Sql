/*
删除测试数据
*/
ALTER  PROC sp_TP_DeleteTestRecord
(
@ID int
)
AS
BEGIN
	DELETE FROM dbo.TP_TestRecord  WHERE id=@ID
	DELETE FROM dbo.TP_TestDetail WHERE TestRecordID=@ID
	SELECT '1'MsgType,'删除成功'Msg
END 