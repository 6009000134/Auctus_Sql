/*
ɾ��������ϸBSN
*/
ALTER PROCEDURE [dbo].[sp_DeleteSODetail]
(
	@SOID				INT		 ,	--��������
	@BSN				NVARCHAR(50) ,	--BSN���߰�װ���
	@CreateBy			NVARCHAR(50) 
)
AS

BEGIN
	--���������
	IF EXISTS(SELECT 1 FROM dbo.qz_SO WHERE Id = @SOID AND Status=1)
	BEGIN
		SELECT '0' AS MsgType, '���۵��Ѿ���ɣ� ������ɾ��SN��' AS Msg;
		RETURN
	END

	DELETE FROM dbo.qz_SODetail WHERE SOID=@SOID AND (BSN=@BSN OR ISNULL(@BSN,'')='')
	SELECT '1' AS MsgType, 'ɾ���ɹ���' AS Msg;
	
END