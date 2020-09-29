/*
销售产品追溯
*/
ALTER PROCEDURE [dbo].[sp_QZSOSNReview]
(
	 @SN		VARCHAR(50) = '001AVGZ056'
)
AS

--DECLARE @SN		VARCHAR(50) = 'HEF0903'

BEGIN
	--获取出货单主键
	DECLARE @MainId BIGINT; --= ''

	SELECT @MainId = MainId FROM dbo.qz_SaleDeliverDtl WHERE BSN = @SN

	IF @MainId IS NULL
	BEGIN
		SELECT 'Error' AS MsgType, '该SN未出货或不存在！' AS Msg;
		RETURN
	END

	SELECT 'Success' AS MsgType, '' AS Msg;

	--出货单信息
	SELECT a.Id, a.DeliverNo, a.DeliverDate, a.State, a.DeliverNum, a.MateNo, a.AgentNo, b.AgentName, a.CreateBy, a.CreateDate
	FROM dbo.qz_SaleDeliver a LEFT JOIN dbo.qz_SaleAgent b ON a.AgentNo = b.AgentNo
	WHERE a.Id = @MainId


	--包装箱信息
	SELECT b.AucId, b.AuVenSN, b.LogTime, b.PackDate, b.PackageSN, b.PackNo, b.PackNum, b.AuctusWPO, b.CreateBy, 
		c.MO, c.AucPOQty, d.AucMateCode, d.AucMateName, d.MateCode, d.MateName
	FROM dbo.AucWPOPackageDtl a INNER JOIN dbo.AucWPOPackage b ON a.AucId = b.AucId
		LEFT JOIN dbo.AucWPOFun c ON b.AuVenSN = c.AuVenSN AND b.MOId = c.Id
		LEFT JOIN dbo.AucWPOMate d ON c.AuVenSN = d.AuVenSN AND c.AucMateId = d.Id
	WHERE a.BSN = @SN
	

	--SN ATE 测试信息
	SELECT * FROM dbo.AucAtetest WHERE BSN = @SN ORDER BY AucId DESC
	--SELECT * FROM dbo.AucWPOMate 

	SELECT b.DocNo,b.Status,b.Quantity,b.DeliverDate,c.Code SOAgentCode,c.Name SOAgentName,b.MaterialCode,b.MaterialName,a.BSN,a.PackageNO,b.CreateBy,b.CreateDate
	FROM dbo.qz_SODetail a INNER JOIN dbo.qz_SO b ON a.SOID=b.ID LEFT JOIN dbo.qz_SOAgent c ON b.SOAgentID=c.ID
	WHERE a.BSN=@SN
	
END