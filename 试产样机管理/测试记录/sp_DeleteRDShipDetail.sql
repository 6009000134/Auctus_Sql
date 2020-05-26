/*
删除研发出库明细数据
*/
Alter PROC sp_DeleteRDShipDetail
(
@SNCode VARCHAR(100),
@ShipID INT
)
AS
BEGIN
	--TODO:判断是否已经出库
	IF	ISNULL(@SNCode,'')=''
	BEGIN
		DELETE FROM dbo.TP_RDShipDetail WHERE ShipID=@ShipID
		SELECT '1'MsgType,'清除成功！'Msg
	END 
	ELSE
    BEGIN
		DELETE FROM dbo.TP_RDShipDetail WHERE ShipID=@ShipID AND SNCode=@SNCode
		SELECT '1'MsgType,'['+@SNCode+']删除成功！'Msg
	END 

END 