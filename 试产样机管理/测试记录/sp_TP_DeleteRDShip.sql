/*
删除测试数据
*/
ALTER PROC sp_TP_DeleteRDShip
(
@ID int
)
AS
BEGIN
	IF EXISTS (SELECT 1 FROM dbo.TP_RDShip a WHERE a.ID=@ID AND a.Status!='0')
	BEGIN 
		SELECT '0'MsgType,'单据不是开立状态，不可删除！'Msg		
	END 
	ELSE 
	BEGIN
		DELETE FROM dbo.TP_RDShip  WHERE id=@ID
		DELETE FROM dbo.TP_RDShipDetail WHERE ShipID=@ID
		SELECT '1'MsgType,'删除成功'Msg
	END 
END 