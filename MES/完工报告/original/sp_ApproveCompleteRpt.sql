/*
�깤�������
*/
ALTER  PROC sp_ApproveCompleteRpt
(
@DocNo VARCHAR(30)
)
AS
BEGIN
	--TODO:У���߼�
	UPDATE dbo.mxqh_CompleteRpt SET Status=2 WHERE DocNo=@DocNo
	SELECT '1' MsgType,'���ͨ����'Msg
END 