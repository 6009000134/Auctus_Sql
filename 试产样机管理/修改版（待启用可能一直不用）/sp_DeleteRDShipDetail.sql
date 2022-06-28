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
	--TODO:判断是否已经出库
	IF EXISTS (SELECT 1 FROM dbo.TP_RDShip a WHERE a.ID=@ShipID AND a.Status!='0')
	BEGIN 
		SELECT '0'MsgType,'单据不是开立状态，不可删除！'Msg		
	END 
	ELSE 
	BEGIN
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

END
GO