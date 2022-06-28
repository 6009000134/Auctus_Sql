SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[sp_DeleteRDShipDetail]
(
@SNCode VARCHAR(100),
@ShipID INT
)
AS
BEGIN
	--TODO:�ж��Ƿ��Ѿ�����
	IF EXISTS (SELECT 1 FROM dbo.TP_RDShip a WHERE a.ID=@ShipID AND a.Status!='0')
	BEGIN 
		SELECT '0'MsgType,'���ݲ��ǿ���״̬������ɾ����'Msg		
	END 
	ELSE 
	BEGIN
		IF	ISNULL(@SNCode,'')=''
		BEGIN
			DELETE FROM dbo.TP_RDShipDetail WHERE ShipID=@ShipID
			SELECT '1'MsgType,'����ɹ���'Msg
		END 
		ELSE
		BEGIN
			DELETE FROM dbo.TP_RDShipDetail WHERE ShipID=@ShipID AND SNCode=@SNCode
			SELECT '1'MsgType,'['+@SNCode+']ɾ���ɹ���'Msg
		END 
	END 

END
GO