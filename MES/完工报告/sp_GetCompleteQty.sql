/*
Update(2020-4-16)
报废数量不算投入数，这样U9才能反开工把废料退出来
Update(2020-5-12)
投入数量改成完工数量，当U9反开工后，开工数量>mes完工数量，则允许反开工
*/
ALTER PROCEDURE [dbo].[sp_GetCompleteQty]
(
@WorkOrder VARCHAR(30),
@U9CompleteQty INT
)
AS
BEGIN
--DECLARE @WorkOrder VARCHAR(30)='AMO-30190814060'

--判断工单是否通过完工报告校验
DECLARE @CompleteType INT--0/1--非完工报告/完工报告
DECLARE @WorkOrderID INT
SELECT @WorkOrderID=a.ID,@CompleteType=ISNULL(a.CompleteType,0) FROM dbo.mxqh_plAssemblyPlanDetail a WHERE a.WorkOrder=@WorkOrder
DECLARE @CompleteQty INT=0,@OnLineQty INT=0
IF @CompleteType=0
BEGIN--非完工报告
	IF EXISTS(SELECT 1 FROM dbo.op_IPQCMain)
	BEGIN		
		SELECT @CompleteQty=COUNT(a.PackNum),@OnLineQty=-1 FROM dbo.op_IPQCMain a WHERE a.Result=1
	END 
	ELSE IF EXISTS(SELECT 1 FROM dbo.opPackageMain a INNER JOIN dbo.opPackageDetail b ON a.ID=b.PackMainID INNER JOIN dbo.opPackageChild c ON b.ID=c.PackDetailID
	WHERE a.AssemblyPlanDetailID=@WorkOrderID) OR EXISTS(SELECT 1 FROM dbo.opPlanExecutMainPK a WHERE a.AssemblyPlanDetailID=@WorkOrderID)
	BEGIN--包装
		--包装上线	
		SELECT @CompleteQty=SUM(CompleteQty)
		,@OnLineQty=SUM(t.CompleteQty)
		FROM (
		SELECT ISNULL(COUNT(t.IsPass),0)CompleteQty FROM
		(
		SELECT ROW_NUMBER()OVER(PARTITION BY a.InternalCode,a.ID ORDER BY c.OrderNum DESC,ISNULL(c.PassTime,FORMAT(GETDATE(),'yyyy-MM-dd HH:mm:ss')))RN,c.IsPass
		FROM dbo.opPlanExecutMainPK a INNER JOIN dbo.opPlanExecutDetailPK c ON a.ID=c.PlanExecutMainID
		WHERE a.AssemblyPlanDetailID=@WorkOrderID AND c.ExtendOne=0
		) t WHERE t.RN=1 AND t.IsPass=1
		--包装未上线前以时间包装统计---2020/03/24之前
		UNION ALL
		SELECT COUNT(1)CompleteQty-- 最后一工位算合格
		FROM dbo.opPackageChild a  INNER JOIN dbo.opPackageDetail b ON a.PackDetailID = b.ID INNER JOIN dbo.opPackageMain c ON b.PackMainID = c.ID
		WHERE a.TS < '2020/03/24 00:00' --AND c.AssemblyPlanDetailID=1
		AND c.AssemblyPlanDetailID=@WorkOrderID
		) t
	END 
	ELSE IF EXISTS(SELECT 1 FROM dbo.opPlanExecutMain a WHERE a.AssemblyPlanDetailID=@WorkOrderID)--组装工单,取上线最后一个工序通过数量
	BEGIN 
		SELECT @CompleteQty=ISNULL(COUNT(t.IsPass),0)
		,@OnLineQty=ISNULL(COUNT(t.IsPass),0)
		FROM
		(
		SELECT ROW_NUMBER()OVER(PARTITION BY a.InternalCode,a.ID ORDER BY c.OrderNum DESC,ISNULL(c.PassTime,FORMAT(GETDATE(),'yyyy-MM-dd HH:mm:ss')))RN,c.IsPass
		FROM dbo.opPlanExecutMain a INNER JOIN dbo.opPlanExecutDetail c ON a.ID=c.PlanExecutMainID
		WHERE a.AssemblyPlanDetailID=@WorkOrderID AND c.ExtendOne=0
		) t WHERE t.RN=1 AND t.IsPass=1
	END 	
	ELSE IF EXISTS(SELECT 1 FROM dbo.opPlanExecutMainHH a WHERE a.AssemblyPlanDetailID=@WorkOrderID)--后焊工单完工信息
	BEGIN
		SELECT @CompleteQty=ISNULL(COUNT(t.IsPass),0)
		,@OnLineQty=ISNULL(COUNT(t.IsPass),0)
		FROM
		(
		SELECT ROW_NUMBER()OVER(PARTITION BY a.InternalCode,a.ID ORDER BY c.OrderNum desc,ISNULL(c.PassTime,FORMAT(GETDATE(),'yyyy-MM-dd HH:mm:ss')))RN,c.IsPass
		FROM dbo.opPlanExecutMainHH a INNER JOIN dbo.opPlanExecutDetailHH c ON a.ID=c.PlanExecutMainID
		WHERE a.AssemblyPlanDetailID=@WorkOrderID AND c.ExtendOne=0
		) t WHERE t.RN=1 AND t.IsPass=1
	END 
END --非完工报告
ELSE
BEGIN--完工报告
	--完工报告数量
	SELECT 	@CompleteQty=ISNULL(SUM(a.CompleteQty),0),@OnLineQty=-1 
	FROM dbo.mxqh_CompleteRpt a INNER JOIN dbo.mxqh_plAssemblyPlanDetail b ON a.WorkOrderID=b.ID
	WHERE a.WorkOrder=@WorkOrder
END --完工报告

IF @U9CompleteQty>@CompleteQty
BEGIN
SELECT '1'MsgType,'MES完工数量不足，无法创建完工报告。MES录入完工数量：'+CONVERT(VARCHAR(50),ISNULL(@CompleteQty,0))+',U9录入完工数量：'+CONVERT(VARCHAR(50),@U9CompleteQty) Msg
END 
ELSE
BEGIN
	SELECT '0'MsgType ,''Msg
END 



END