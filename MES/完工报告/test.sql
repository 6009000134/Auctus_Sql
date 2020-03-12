--SELECT * FROM dbo.mxqh_plAssemblyPlanDetail WHERE Status=0

--SELECT * FROM 
--	(
--	SELECT b.WorkOrder,b.MaterialCode,b.MaterialName,ROW_NUMBER()OVER(PARTITION BY a.InternalCode ORDER BY c.OrderNum desc)RN,a.InternalCode,c.IsPass,c.OrderNum,(SELECT COUNT(1) FROM dbo.opPlanExecutMain op WHERE op.AssemblyPlanDetailID=a.AssemblyPlanDetailID) OnLineQty
--	FROM dbo.opPlanExecutMain a INNER JOIN dbo.mxqh_plAssemblyPlanDetail b ON a.AssemblyPlanDetailID=b.ID
--	INNER JOIN dbo.opPlanExecutDetail c ON a.ID=c.PlanExecutMainID
--	--INNER JOIN dbo.opPlanExecutChild d ON c.ID=d.PlanExecutDetailID
--	WHERE c.ExtendOne=0 AND b.Status=0
--	) t WHERE t.RN=1 AND t.IsPass=0

	--SELECT DocNo,StartDate,ActualStartDate,DocState,ProductQty INTO #tempTable FROM U9DATA.AuctusERP.dbo.MO_MO
	--SELECT * FROM #tempTable a INNER JOIN dbo.mxqh_plAssemblyPlanDetail
	;
	WITH data1 as
	(SELECT a.WorkOrder,a.MaterialID,a.MaterialName,a.Quantity,a.Status,b.docstate FROM dbo.mxqh_plAssemblyPlanDetail a LEFT JOIN #tempTable b ON a.WorkOrder=b.docno
	WHERE a.Status=0 AND b.docstate<3
	),
	data2 AS
    (
		SELECT DISTINCT b.WorkOrder,b.Quantity
	FROM dbo.opPlanExecutMain a INNER JOIN dbo.mxqh_plAssemblyPlanDetail b ON a.AssemblyPlanDetailID=b.ID
	INNER JOIN dbo.opPlanExecutDetail c ON a.ID=c.PlanExecutMainID
	--INNER JOIN dbo.opPlanExecutChild d ON c.ID=d.PlanExecutDetailID
	WHERE c.ExtendOne=0 AND b.Status=0
		)
	SELECT a.WorkOrder,a.MaterialName,'开立' MES状态,'已核准' U9状态 FROM data1 a LEFT JOIN data2 b ON a.WorkOrder=b.WorkOrder
	WHERE ISNULL(b.WorkOrder,'')<>''

	--	SELECT DISTINCT b.WorkOrder,b.Quantity
	--FROM dbo.opPlanExecutMain a INNER JOIN dbo.mxqh_plAssemblyPlanDetail b ON a.AssemblyPlanDetailID=b.ID
	--INNER JOIN dbo.opPlanExecutDetail c ON a.ID=c.PlanExecutMainID
	----INNER JOIN dbo.opPlanExecutChild d ON c.ID=d.PlanExecutDetailID
	--WHERE c.ExtendOne=0 AND b.Status=0
