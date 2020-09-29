/*
删除销售明细BSN
*/
ALTER PROCEDURE [dbo].[sp_DeleteSODetail]
(
	@SOID				INT		 ,	--出货单号
	@BSN				NVARCHAR(50) ,	--BSN或者包装箱号
	@CreateBy			NVARCHAR(50) 
)
AS

BEGIN
	--定义出货量
	IF EXISTS(SELECT 1 FROM dbo.qz_SO WHERE Id = @SOID AND Status=1)
	BEGIN
		SELECT '0' AS MsgType, '销售单已经完成， 不允许删除SN！' AS Msg;
		RETURN
	END

	DELETE FROM dbo.qz_SODetail WHERE SOID=@SOID AND (BSN=@BSN OR ISNULL(@BSN,'')='')
	SELECT '1' AS MsgType, '删除成功！' AS Msg;
	
END