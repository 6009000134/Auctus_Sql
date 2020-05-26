/*
删除测试明细数据
*/
ALTER PROC sp_DeleteTestRecordDetail
(
@SNCode VARCHAR(100),
@TestRecordID INT
)
AS
BEGIN
	--TODO:判断是否已经出库
	IF	ISNULL(@SNCode,'')=''
	BEGIN
		DELETE FROM dbo.TP_TestDetail WHERE TestRecordID=@TestRecordID
		SELECT '1'MsgType,'清除成功！'Msg
	END 
	ELSE
    BEGIN
		DELETE FROM dbo.TP_TestDetail WHERE TestRecordID=@TestRecordID AND SNCode=@SNCode
		SELECT '1'MsgType,'['+@SNCode+']删除成功！'Msg
	END 

END 