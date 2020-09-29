/*
关闭订单
*/
ALTER PROC [dbo].[sp_QZSODone]
(
@SOID INT,
@IsFinish BIT ,
@CreateBy VARCHAR(50)
)
AS
BEGIN

	DECLARE @DetailCount INT=ISNULL((SELECT COUNT(1) FROM dbo.qz_SODetail WHERE SOID=@SOID),0)
	DECLARE @Quantity INT=(SELECT quantity FROM dbo.qz_SO WHERE id=@SOID)
	IF	@Quantity>@DetailCount
	BEGIN
		SELECT '0' MsgType,'销售订单未扫完所有SN码，不能关闭！'Msg
		return
	END
	IF @IsFinish=0
	BEGIN
		UPDATE dbo.qz_SO SET Quantity=(SELECT COUNT(1) FROM dbo.qz_SODetail b WHERE b.SOID=dbo.qz_SO.ID),ModifyBy=@CreateBy,ModifyDate=GETDATE() WHERE ID=@SOID
		SELECT '2' MsgType,'更新销售数量但是不关闭单据！'Msg
	END 
	ELSE
	BEGIN
		UPDATE dbo.qz_SO SET Status=1,Quantity=(SELECT COUNT(1) FROM dbo.qz_SODetail b WHERE b.SOID=dbo.qz_SO.ID),ModifyBy=@CreateBy,ModifyDate=GETDATE() WHERE ID=@SOID
		SELECT '1' MsgType,'成功关闭订单！'Msg
	END  
	
	SELECT a.*,(SELECT COUNT(1) FROM dbo.qz_SODetail b WHERE b.SOID=a.id)HavePackQty FROM dbo.qz_SO a WHERE a.ID=@SOID
END 

