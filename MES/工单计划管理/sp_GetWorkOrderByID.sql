/*
根据工单ID获取工单信息
*/
ALTER PROC sp_GetWorkOrderByID
(
@WorkOrderID INT
)
AS
BEGIN

	--DECLARE @WorkOrderID INT=4092

	DECLARE @CompleteType INT,@CompleteQty INT,@TotalOnLineQty INT,@OnLineQty INT,@DumpQty INT,@OverInputQty INT
	SELECT @CompleteType=CompleteType FROM dbo.mxqh_plAssemblyPlanDetail a WHERE a.ID=@WorkOrderID

	--获取工单数量信息
	IF ISNULL(@CompleteType,0)=0--非完工报告类型
	BEGIN
		IF EXISTS(SELECT 1 FROM dbo.opPackageMain a INNER JOIN dbo.opPackageDetail b ON a.ID=b.PackMainID INNER JOIN dbo.opPackageChild c ON b.ID=c.PackDetailID
		WHERE a.AssemblyPlanDetailID=@WorkOrderID) OR EXISTS(SELECT 1 FROM dbo.opPlanExecutMainPK a WHERE a.AssemblyPlanDetailID=@WorkOrderID)
		BEGIN--包装上线			
			SELECT @CompleteQty=SUM(CompleteQty)
			,@TotalOnLineQty=(SELECT COUNT(1) FROM dbo.opPlanExecutMainPK WHERE AssemblyPlanDetailID=@WorkOrderID)	 
			,@OnLineQty=(SELECT COUNT(1) FROM dbo.opPlanExecutMainPK WHERE AssemblyPlanDetailID=@WorkOrderID AND IsDump=0)	 
			,@DumpQty=(SELECT COUNT(1) FROM dbo.opPlanExecutMainPK WHERE AssemblyPlanDetailID=@WorkOrderID AND IsDump=1)
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
		ELSE IF EXISTS(SELECT 1 FROM dbo.opPlanExecutMain a WHERE a.AssemblyPlanDetailID=@WorkOrderID)
		BEGIN --组装工单,取上线最后一个工序通过数量
			SELECT @CompleteQty=ISNULL(COUNT(t.IsPass),0)
			,@TotalOnLineQty=(SELECT COUNT(1) FROM dbo.opPlanExecutMain WHERE AssemblyPlanDetailID=@WorkOrderID)	 
			,@OnLineQty=(SELECT COUNT(1) FROM dbo.opPlanExecutMain WHERE AssemblyPlanDetailID=@WorkOrderID AND IsDump=0) 
			,@DumpQty=(SELECT COUNT(1) FROM dbo.opPlanExecutMain WHERE AssemblyPlanDetailID=@WorkOrderID AND IsDump=1) 
			FROM
			(
			SELECT ROW_NUMBER()OVER(PARTITION BY a.InternalCode,a.ID ORDER BY c.OrderNum DESC,ISNULL(c.PassTime,FORMAT(GETDATE(),'yyyy-MM-dd HH:mm:ss')))RN,c.IsPass
			FROM dbo.opPlanExecutMain a INNER JOIN dbo.opPlanExecutDetail c ON a.ID=c.PlanExecutMainID
			WHERE a.AssemblyPlanDetailID=@WorkOrderID AND c.ExtendOne=0
			) t WHERE t.RN=1 AND t.IsPass=1
		END 	
		ELSE IF EXISTS(SELECT 1 FROM dbo.opPlanExecutMainHH a WHERE a.AssemblyPlanDetailID=@WorkOrderID)
		BEGIN--后焊工单完工信息
			SELECT @CompleteQty=ISNULL(COUNT(t.IsPass),0)
			,@TotalOnLineQty=(SELECT COUNT(1) FROM dbo.opPlanExecutMainHH WHERE AssemblyPlanDetailID=@WorkOrderID)
			,@OnLineQty=(SELECT COUNT(1) FROM dbo.opPlanExecutMainHH WHERE AssemblyPlanDetailID=@WorkOrderID AND IsDump=0) 
			,@DumpQty=(SELECT COUNT(1) FROM dbo.opPlanExecutMainHH WHERE AssemblyPlanDetailID=@WorkOrderID AND IsDump=1) 
			FROM
			(
			SELECT ROW_NUMBER()OVER(PARTITION BY a.InternalCode,a.ID ORDER BY c.OrderNum desc,ISNULL(c.PassTime,FORMAT(GETDATE(),'yyyy-MM-dd HH:mm:ss')))RN,c.IsPass
			FROM dbo.opPlanExecutMainHH a INNER JOIN dbo.opPlanExecutDetailHH c ON a.ID=c.PlanExecutMainID
			WHERE a.AssemblyPlanDetailID=@WorkOrderID AND c.ExtendOne=0
			) t WHERE t.RN=1 AND t.IsPass=1
		END 
	END 
	ELSE
	BEGIN
		SELECT @CompleteQty=SUM(a.CompleteQty)
		FROM dbo.mxqh_CompleteRpt a WHERE a.WorkOrderID=@WorkOrderID
	END
	SET @OverInputQty=(SELECT SUM(a.OverInputQty) FROM dbo.mxqh_OverInput a WHERE a.Status=2 AND a.WorkOrderID=@WorkOrderID)
	SELECT a.ID,a.WorkOrder,a.MaterialID,b.MaterialCode,b.MaterialName,a.Quantity,a.TotalStartQty,@CompleteQty CompleteQty,@OnLineQty OnLineQty,@TotalOnLineQty TotalOnLineQty
	,@DumpQty DumpQty,@OverInputQty OverInputQty
	FROM dbo.mxqh_plAssemblyPlanDetail a INNER JOIN dbo.mxqh_Material b ON a.MaterialID=b.Id
	WHERE a.ID=@WorkOrderID


END 

