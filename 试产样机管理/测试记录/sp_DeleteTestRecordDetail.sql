/*
ɾ��������ϸ����
*/
ALTER PROC sp_DeleteTestRecordDetail
(
@SNCode VARCHAR(100),
@TestRecordID INT
)
AS
BEGIN
	--TODO:�ж��Ƿ��Ѿ�����
	IF	ISNULL(@SNCode,'')=''
	BEGIN
		DELETE FROM dbo.TP_TestDetail WHERE TestRecordID=@TestRecordID
		SELECT '1'MsgType,'����ɹ���'Msg
	END 
	ELSE
    BEGIN
		DELETE FROM dbo.TP_TestDetail WHERE TestRecordID=@TestRecordID AND SNCode=@SNCode
		SELECT '1'MsgType,'['+@SNCode+']ɾ���ɹ���'Msg
	END 

END 