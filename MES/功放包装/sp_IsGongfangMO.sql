/*
检测是否为功放产品，并返回订单信息
*/
ALTER  PROC sp_IsGongfangMO
(
@WorkOrder nvarchar(30)
)
AS
BEGIN

	--DECLARE @WorkOrder NVARCHAR(30)='MO-30191008004'
	--料品是否为功放产品
	IF EXISTS(SELECT 1 FROM dbo.mxqh_plAssemblyPlanDetail a INNER JOIN dbo.mxqh_Material m ON a.MaterialID=m.Id WHERE m.MaterialTypeID=5 AND a.WorkOrder=@WorkOrder)
	--IF EXISTS(SELECT 1 FROM dbo.mxqh_plAssemblyPlanDetail a INNER JOIN dbo.mxqh_Material m ON a.MaterialID=m.Id WHERE a.WorkOrder=@WorkOrder)
	BEGIN
		SELECT '1' MsgType,'' Msg
		SELECT a.ID,a.TransID,b.MaterialCode,b.MaterialName,a.CustomPartNo,a.Model,a.PackListNo,a.Tanapa,a.PlanQuantity,b.ERPQuantity,b.ERPSO 
		,a.SendPlaceName,a.PerBoxQuantity,a.PerColorBoxQty
		FROM opPackageMain a INNER JOIN dbo.mxqh_plAssemblyPlanDetail b ON a.AssemblyPlanDetailID=b.ID
		WHERE b.WorkOrder=@WorkOrder
	END 
	ELSE
    BEGIN
		SELECT '0' MsgType,'此工单不是功放工单，请使用产品包装功能！' Msg
	END
	 

END 

--SELECT * FROM dbo.mxqh_plAssemblyPlanDetail ORDER BY CreateDate DESC

--SELECT *FROM dbo.baMaterialType
