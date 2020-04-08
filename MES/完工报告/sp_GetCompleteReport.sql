/*
工单完工情况查询
update 2020-3-31 完工数量从系统统计表取值
*/
alter PROC sp_GetCompleteReport
(
@pageSize INT,
@pageIndex INT,
@WorkOrder VARCHAR(30)
)
AS
BEGIN
--DECLARE @WorkOrder VARCHAR(30)='AMO-30190814060'
DECLARE @beginIndex INT=@pageSize*(@pageIndex-1)
DECLARE @endIndex INT=@pageSize*@pageIndex+1

DECLARE @Quantity INT
DECLARE @WorkOrderID INT=(SELECT id FROM dbo.mxqh_plAssemblyPlanDetail WHERE WorkOrder=@WorkOrder)

SELECT @Quantity=Quantity FROM dbo.mxqh_plAssemblyPlanDetail WHERE WorkOrder=@WorkOrder
DECLARE @CompleteType INT=(SELECT ISNULL(CompleteType,0) FROM dbo.mxqh_plAssemblyPlanDetail WHERE WorkOrder=@WorkOrder)
IF @CompleteType=0
BEGIN--非完工报告类型
	--包装工单
	IF EXISTS(SELECT 1 FROM dbo.opPackageMain a INNER JOIN dbo.opPackageDetail b ON a.ID=b.PackMainID INNER JOIN dbo.opPackageChild c ON b.ID=c.PackDetailID
	WHERE a.AssemblyPlanDetailID=@WorkOrderID)
	OR EXISTS(SELECT 1 FROM dbo.opPlanExecutMainPK a WHERE a.AssemblyPlanDetailID=@WorkOrderID)
	BEGIN
		SELECT a.WorkOrder,c.MaterialCode,c.MaterialName--,a.Quantity,b.FinishSum CompleteQty,a.Quantity-b.FinishSum UnCompleteQty
		,MIN(a.Quantity)Quantity,SUM(ISNULL(b.FinishSum,0))CompleteQty,MIN(a.Quantity)-SUM(ISNULL(b.FinishSum,0))UnCompleteQty
		,(SELECT COUNT(1) FROM dbo.opPlanExecutMainPK op WHERE op.AssemblyPlanDetailID=a.ID) OnLineQty
		FROM dbo.mxqh_plAssemblyPlanDetail  a LEFT JOIN dbo.mx_PlanExBackNumMain b ON a.ID=b.AssemblyPlanDetailID
		LEFT JOIN dbo.mxqh_Material c ON a.MaterialID=c.Id
		WHERE a.WorkOrder=@WorkOrder
		GROUP BY a.ID,a.WorkOrder,c.MaterialCode,c.MaterialName
		
		--未完工内控码集合
		SELECT * FROM (
		SELECT t.InternalCode,t.IsPass,t.IsDump,ROW_NUMBER()OVER(ORDER BY t.InternalCode)RN FROM 
		(
		SELECT ROW_NUMBER()OVER(PARTITION BY a.InternalCode,a.ID ORDER BY c.OrderNum desc,ISNULL(c.PassTime,FORMAT(GETDATE(),'yyyy-MM-dd HH:mm:ss'))desc)RN,a.InternalCode,c.IsPass,c.OrderNum
		,CASE WHEN ISNULL(d.MainId,0)=0 THEN '否' ELSE '是'END  IsDump
		FROM dbo.opPlanExecutMainPK a INNER JOIN dbo.mxqh_plAssemblyPlanDetail b ON a.AssemblyPlanDetailID=b.ID
		INNER JOIN dbo.opPlanExecutDetailPK c ON a.ID=c.PlanExecutMainID LEFT JOIN opPlanExecutMainDump d ON a.ID=d.MainId
		WHERE b.WorkOrder=@WorkOrder  AND c.ExtendOne=0
		) t WHERE t.RN=1 AND t.IsPass=0
		) t1 WHERE t1.RN>@beginIndex AND t1.RN<@endIndex
		--未完工内控码总数
		SELECT COUNT(1)Count FROM 
		(
		SELECT ROW_NUMBER()OVER(PARTITION BY a.InternalCode,a.ID ORDER BY c.OrderNum desc,ISNULL(c.PassTime,FORMAT(GETDATE(),'yyyy-MM-dd HH:mm:ss'))desc)RN,a.InternalCode,c.IsPass,c.OrderNum
		FROM dbo.opPlanExecutMain a INNER JOIN dbo.mxqh_plAssemblyPlanDetail b ON a.AssemblyPlanDetailID=b.ID
		INNER JOIN dbo.opPlanExecutDetail c ON a.ID=c.PlanExecutMainID
		--INNER JOIN dbo.opPlanExecutChild d ON c.ID=d.PlanExecutDetailID
		WHERE b.WorkOrder=@WorkOrder AND c.ExtendOne=0
		) t WHERE t.RN=1 AND t.IsPass=0

		RETURN;
	END 

	--判断料品、工单是否有工艺
	IF EXISTS(SELECT 1 FROM dbo.opPlanExecutMain a WHERE a.AssemblyPlanDetailID=@WorkOrderID)--有工艺工单，完工数量查最后一个工序数据
	BEGIN	
		----完工信息
		SELECT a.WorkOrder,c.MaterialCode,c.MaterialName--,a.Quantity,b.FinishSum CompleteQty,a.Quantity-b.FinishSum UnCompleteQty
		,MIN(a.Quantity)Quantity,SUM(ISNULL(b.FinishSum,0))CompleteQty,MIN(a.Quantity)-SUM(ISNULL(b.FinishSum,0))UnCompleteQty
		,(SELECT COUNT(1) FROM dbo.opPlanExecutMain op WHERE op.AssemblyPlanDetailID=a.ID) OnLineQty
		FROM dbo.mxqh_plAssemblyPlanDetail  a LEFT JOIN dbo.mx_PlanExBackNumMain b ON a.ID=b.AssemblyPlanDetailID
		LEFT JOIN dbo.mxqh_Material c ON a.MaterialID=c.Id
		WHERE a.WorkOrder=@WorkOrder
		GROUP BY a.ID,a.WorkOrder,c.MaterialCode,c.MaterialName
		--SELECT MIN(t.WorkOrder)WorkOrder,MIN(t.MaterialCode)MaterialCode,MIN(t.MaterialName)MaterialName
		--,@Quantity Quantity,COUNT(*)CompleteQty,@Quantity-COUNT(*)UnCompleteQty,MIN(t.OnLineQty)OnLineQty FROM 
		--(
		--SELECT b.WorkOrder,b.MaterialCode,b.MaterialName,ROW_NUMBER()OVER(PARTITION BY a.InternalCode,a.ID ORDER BY c.OrderNum DESC,ISNULL(c.PassTime,FORMAT(GETDATE(),'yyyy-MM-dd HH:mm:ss'))desc)RN,a.InternalCode,c.IsPass,c.OrderNum,(SELECT COUNT(1) FROM dbo.opPlanExecutMain op WHERE op.AssemblyPlanDetailID=a.AssemblyPlanDetailID) OnLineQty
		--FROM dbo.opPlanExecutMain a INNER JOIN dbo.mxqh_plAssemblyPlanDetail b ON a.AssemblyPlanDetailID=b.ID
		--INNER JOIN dbo.opPlanExecutDetail c ON a.ID=c.PlanExecutMainID
		----INNER JOIN dbo.opPlanExecutChild d ON c.ID=d.PlanExecutDetailID
		--WHERE b.WorkOrder=@WorkOrder AND c.ExtendOne=0
		--) t WHERE t.RN=1 AND t.IsPass=1
	
		--未完工内控码集合
		SELECT * FROM (
		SELECT t.InternalCode,t.IsPass,t.IsDump,ROW_NUMBER()OVER(ORDER BY t.InternalCode)RN FROM 
		(
		SELECT ROW_NUMBER()OVER(PARTITION BY a.InternalCode,a.ID ORDER BY c.OrderNum desc,ISNULL(c.PassTime,FORMAT(GETDATE(),'yyyy-MM-dd HH:mm:ss'))desc)RN,a.InternalCode,c.IsPass,c.OrderNum
		,CASE WHEN ISNULL(d.MainId,0)=0 THEN '否' ELSE '是'END  IsDump
		FROM dbo.opPlanExecutMain a INNER JOIN dbo.mxqh_plAssemblyPlanDetail b ON a.AssemblyPlanDetailID=b.ID
		INNER JOIN dbo.opPlanExecutDetail c ON a.ID=c.PlanExecutMainID LEFT JOIN opPlanExecutMainDump d ON a.ID=d.MainId
		--INNER JOIN dbo.opPlanExecutChild d ON c.ID=d.PlanExecutDetailID
		WHERE b.WorkOrder=@WorkOrder  AND c.ExtendOne=0
		) t WHERE t.RN=1 AND t.IsPass=0
		) t1 WHERE t1.RN>@beginIndex AND t1.RN<@endIndex
		--未完工内控码总数
		SELECT COUNT(1)Count FROM 
		(
		SELECT ROW_NUMBER()OVER(PARTITION BY a.InternalCode,a.ID ORDER BY c.OrderNum desc,ISNULL(c.PassTime,FORMAT(GETDATE(),'yyyy-MM-dd HH:mm:ss'))desc)RN,a.InternalCode,c.IsPass,c.OrderNum
		FROM dbo.opPlanExecutMain a INNER JOIN dbo.mxqh_plAssemblyPlanDetail b ON a.AssemblyPlanDetailID=b.ID
		INNER JOIN dbo.opPlanExecutDetail c ON a.ID=c.PlanExecutMainID
		--INNER JOIN dbo.opPlanExecutChild d ON c.ID=d.PlanExecutDetailID
		WHERE b.WorkOrder=@WorkOrder AND c.ExtendOne=0
		) t WHERE t.RN=1 AND t.IsPass=0
	
		RETURN ;
	END 

	--后焊工单完工信息
	IF EXISTS(SELECT 1 FROM dbo.opPlanExecutMainHH a WHERE a.AssemblyPlanDetailID=@WorkOrderID)
	BEGIN
		--完工信息
	
		SELECT a.WorkOrder,c.MaterialCode,c.MaterialName--,a.Quantity,b.FinishSum CompleteQty,a.Quantity-b.FinishSum UnCompleteQty
		,MIN(a.Quantity)Quantity,SUM(ISNULL(b.FinishSum,0))CompleteQty,MIN(a.Quantity)-SUM(ISNULL(b.FinishSum,0))UnCompleteQty
		,(SELECT COUNT(1) FROM dbo.opPlanExecutMainHH op WHERE op.AssemblyPlanDetailID=a.ID) OnLineQty
		FROM dbo.mxqh_plAssemblyPlanDetail  a LEFT JOIN dbo.mx_PlanExBackNumMain b ON a.ID=b.AssemblyPlanDetailID
		LEFT JOIN dbo.mxqh_Material c ON a.MaterialID=c.Id
		WHERE a.WorkOrder=@WorkOrder
		GROUP BY a.ID,a.WorkOrder,c.MaterialCode,c.MaterialName
	
		--未完工内控码集合
		SELECT * FROM (
		SELECT t.InternalCode,t.IsPass,t.IsDump,ROW_NUMBER()OVER(ORDER BY t.InternalCode)RN FROM 
		(
		SELECT ROW_NUMBER()OVER(PARTITION BY a.InternalCode,a.ID ORDER BY c.OrderNum desc,ISNULL(c.PassTime,FORMAT(GETDATE(),'yyyy-MM-dd HH:mm:ss'))desc)RN,a.InternalCode,c.IsPass,c.OrderNum
		,CASE WHEN ISNULL(d.MainId,0)=0 THEN '否' ELSE '是'END  IsDump
		FROM dbo.opPlanExecutMainHH a INNER JOIN dbo.mxqh_plAssemblyPlanDetail b ON a.AssemblyPlanDetailID=b.ID
		INNER JOIN dbo.opPlanExecutDetailHH c ON a.ID=c.PlanExecutMainID
		LEFT JOIN dbo.opPlanExecutMainDumpHH d ON a.ID=d.MainId
		WHERE b.WorkOrder=@WorkOrder  AND c.ExtendOne=0
		) t WHERE t.RN=1 AND t.IsPass=0
		) t1 WHERE t1.RN>@beginIndex AND t1.RN<@endIndex
		--未完工内控码总数
		SELECT COUNT(1)Count FROM 
		(
		SELECT ROW_NUMBER()OVER(PARTITION BY a.InternalCode,a.ID ORDER BY c.OrderNum desc,ISNULL(c.PassTime,FORMAT(GETDATE(),'yyyy-MM-dd HH:mm:ss'))desc)RN,a.InternalCode,c.IsPass,c.OrderNum
		FROM dbo.opPlanExecutMainHH a INNER JOIN dbo.mxqh_plAssemblyPlanDetail b ON a.AssemblyPlanDetailID=b.ID
		INNER JOIN dbo.opPlanExecutDetailHH c ON a.ID=c.PlanExecutMainID
		WHERE b.WorkOrder=@WorkOrder AND c.ExtendOne=0
		) t WHERE t.RN=1 AND t.IsPass=0

		RETURN;
	END 

END --非完工报告类型
ELSE--完工报告类型
--没工艺工单，完工数量查完工报告
BEGIN
	SELECT MIN(t.WorkOrder)WorkOrder,MIN(t.MaterialCode)MaterialCode,MIN(t.MaterialName)MaterialName,MIN(t.Quantity)Quantity,SUM(t.CompleteQty)CompleteQty,MIN(t.Quantity)-SUM(t.CompleteQty)UnCompleteQty ,MIN(t.OnLineQty)OnLineQty
	FROM  (SELECT b.MaterialCode,b.MaterialName,b.Quantity,a.CompleteQty,a.WorkOrder,a.WorkOrderID,(SELECT COUNT(1) FROM dbo.opPlanExecutMain op WHERE op.AssemblyPlanDetailID=b.ID) OnLineQty
	FROM dbo.mxqh_CompleteRpt a INNER JOIN dbo.mxqh_plAssemblyPlanDetail b ON a.WorkOrderID=b.ID
	WHERE a.WorkOrder=@WorkOrder
	) t
	GROUP BY t.WorkOrder
END --完工报告类型


END 