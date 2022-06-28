SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[sp_DeleteRDRcvDetail]
(
@SNCode VARCHAR(100),
@RcvID INT
)
AS
BEGIN
	--TODO:�ж��Ƿ��Ѿ�����
	IF EXISTS (SELECT 1 FROM dbo.TP_RDRcv a WHERE a.ID=@RcvID AND a.Status!='0')
	BEGIN 
		SELECT '0'MsgType,'���ݲ��ǿ���״̬������ɾ����'Msg		
	END 
	ELSE 
	BEGIN
		IF	ISNULL(@SNCode,'')=''--ֻ��ID��˵�������˵����ϸ
		BEGIN
			DELETE FROM dbo.TP_RDRcvDetail WHERE RcvID=@RcvID
			SELECT '1'MsgType,'����ɹ���'Msg
		END 
		ELSE
		BEGIN
			DELETE FROM dbo.TP_RDRcvDetail WHERE RcvID=@RcvID AND (SNCode=@SNCode OR InternalCode=@SNCode)
			SELECT '1'MsgType,'['+@SNCode+']ɾ���ɹ���'Msg
		END 
	END
END
GO