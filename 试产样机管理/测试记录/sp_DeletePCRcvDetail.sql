/*
ɾ����Ʒ���������ϸ����
*/
ALTER PROC sp_DeletePCRcvDetail
(
@SNCode VARCHAR(100),
@RcvID INT
)
AS
BEGIN
	--TODO:�ж��Ƿ��Ѿ�����
	IF	ISNULL(@SNCode,'')=''
	BEGIN
		DELETE FROM dbo.TP_PCRcvDetail WHERE RcvID=@RcvID
		SELECT '1'MsgType,'����ɹ���'Msg
	END 
	ELSE
    BEGIN
		DELETE FROM dbo.TP_PCRcvDetail WHERE RcvID=@RcvID AND SNCode=@SNCode
		SELECT '1'MsgType,'['+@SNCode+']ɾ���ɹ���'Msg
	END 

END 