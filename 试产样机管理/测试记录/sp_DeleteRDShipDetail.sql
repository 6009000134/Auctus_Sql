/*
ɾ���з�������ϸ����
*/
Alter PROC sp_DeleteRDShipDetail
(
@SNCode VARCHAR(100),
@ShipID INT
)
AS
BEGIN
	--TODO:�ж��Ƿ��Ѿ�����
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