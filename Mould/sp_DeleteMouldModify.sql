/*
ɾ�������
*/
ALTER PROC sp_DeleteMouldModify
(
@DocNo VARCHAR(50)
)
AS
BEGIN
	IF EXISTS(SELECT 1 FROM dbo.MouldModify WHERE Status=0 AND DocNo=@DocNo)
	BEGIN
		DELETE FROM dbo.MouldModifySeg WHERE ModifyID IN (SELECT ID FROM dbo.MouldModify WHERE DocNo=@DocNo)
		DELETE FROM dbo.MouldModify WHERE DocNo=@DocNo
		SELECT '1'MsgType,'ɾ���ɹ���'	Msg
	END 
	ELSE IF EXISTS(SELECT 1 FROM dbo.MouldModify WHERE Status=1 AND DocNo=@DocNo)
    BEGIN
		SELECT '0'MsgType,'��������ˣ�����ɾ����'	Msg
	END 
	ELSE
    BEGIN
		SELECT '0'MsgType,'�����ڴ˶�����'	Msg
	END 
	
END 