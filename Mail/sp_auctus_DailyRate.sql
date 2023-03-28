ALTER  PROCEDURE [dbo].[sp_auctus_DailyRate]
AS
BEGIN
--取消VMO
SET NOCOUNT ON 
DECLARE @Date DATE =DATEADD(DAY,-1,CONVERT(DATETIME,FORMAT(GETDATE(),'yyyy-MM-dd 09:30:00')))
WHILE NOT  EXISTS(SELECT 1 FROM dbo.mxqh_MoPlanCount a
WHERE a.PlanDate=FORMAT(@Date,'yyyy-MM-dd'))
BEGIN  
	IF @Date<'2017-01-01'
	BEGIN
		BREAK;
	END 
	ELSE
    BEGIN
    	SET @Date=DATEADD(DAY,-1,@Date)
	END 
END 

--DECLARE @Date datetime ='2020-09-19'
--DECLARE @Date DATETIME='2020-04-07 09:00:00'
--当天已经备份了数据，不再备份
IF EXISTS (SELECT 1 FROM tempdb.dbo.sysobjects WHERE id = OBJECT_ID(N'TEMPDB..#TempMO') AND type = 'U') 
BEGIN DROP TABLE #TempMO END;
CREATE TABLE #TempMO(PlanDate DATE,WorkOrderID int,WorkOrder VARCHAR(50),PlanCount INT,LineID INT,TotalPlanCount INT,NeedRepairNum int)
;
WITH data1 AS--排产工单
(
SELECT a.PlanDate,a.LineId,a.WorkOrder,a.PlanCount FROM dbo.mxqh_MoPlanCount a
WHERE a.PlanDate=FORMAT(@Date,'yyyy-MM-dd')
),
AllWorkOrder AS--排产工单UNION 排班工单
(
SELECT *FROM data1 
UNION ALL
SELECT a.ArrangeDate,a.LineId,a.WorkOrder,a.PlanCount FROM dbo.mxqh_MoLineArrange a
LEFT JOIN data1 b ON a.WorkOrder=b.WorkOrder
WHERE a.ArrangeDate=FORMAT(@Date,'yyyy-MM-dd')
AND ISNULL(b.WorkOrder,'')=''
)
INSERT INTO #TempMO
SELECT 
a.PlanDate,b.ID,a.WorkOrder,SUM(a.PlanCount)PlanCount,MIN(c.AssemblyLineID)LineID
,(ISNULL((SELECT SUM(t.FinishSum) 
FROM dbo.mx_PlanExBackNumMain t 
INNER JOIN dbo.mxqh_plAssemblyPlanDetail t1 ON t.AssemblyPlanDetailID=t1.ID
WHERE t.OpDate<a.PlanDate AND t1.WorkOrder=a.WorkOrder GROUP BY t1.WorkOrder),0)+ISNULL(SUM(a.PlanCount),0))
TotalPlanCount
,0
FROM AllWorkOrder a INNER JOIN dbo.mxqh_plAssemblyPlanDetail b ON a.WorkOrder=b.WorkOrder 
INNER JOIN dbo.mxqh_plAssemblyPlan c ON b.AssemblyPlanID=c.ID
WHERE 1=1
AND b.VenNo=(SELECT ParaValue FROM dbo.SysPara WHERE ParaName='MainVenNo')
AND PATINDEX('VMO%',a.workorder)=0
--AND WorkOrder='AMO-30191204001'
AND  a.PlanDate=FORMAT(@Date,'yyyy-MM-dd')
GROUP BY a.PlanDate,a.WorkOrder,b.ID
HAVING SUM(a.PlanCount)>0--存在排产数量为0的排产计划

--获取待维修数量
BEGIN
    DECLARE @IsNow		    BIT = 0		
	SET @IsNow = ISNULL(@IsNow, 1);

	IF EXISTS (SELECT 1 FROM tempdb.dbo.sysobjects WHERE id = OBJECT_ID(N'TEMPDB..#TBORDER') AND type = 'U') BEGIN DROP TABLE #TBORDER END;

	SELECT ID, WorkOrder INTO #TBORDER FROM dbo.mxqh_plAssemblyPlanDetail WHERE WorkOrder IN (
SELECT WorkOrder FROM #TempMO
)


	IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#TbMain') AND TYPE='U') BEGIN DROP  TABLE #TbMain END;
	CREATE TABLE #TbMain(ID BIGINT, MOID BIGINT, RouteID BIGINT, TS DATETIME, InternalCode NVARCHAR(30), IsDump BIT)
	--优先从组装查询数据
	
	INSERT INTO #TbMain (a.ID, MOID, RouteID, TS, InternalCode, IsDump)
	SELECT a.ID, a.AssemblyPlanDetailID, a.RoutingID, a.TS, a.InternalCode, a.IsDump FROM dbo.opPlanExecutMain a WHERE AssemblyPlanDetailID IN  (SELECT ID FROM #TBORDER)
	UNION ALL
	SELECT a.ID, a.AssemblyPlanDetailID, a.RoutingID, a.TS, a.InternalCode, a.IsDump FROM au_mes_bak.dbo.opPlanExecutMain_Back a WHERE AssemblyPlanDetailID  IN  (SELECT ID FROM #TBORDER)


	--详细表信息获取
	IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#TbDtl') AND TYPE='U') BEGIN DROP  TABLE #TbDtl END;
	SELECT TOP 0 a.ID, a.MOID, a.RouteID, a.TS, a.InternalCode, a.IsDump, b.ProcedureID, b.ProcedureName, b.OrderNum, b.OperatorDate, b.IsPass, b.IsRepair, CONVERT(NVARCHAR(30), '') CreateBy, b.OperatorID 
	INTO #TbDtl
	FROM #TbMain a INNER JOIN dbo.opPlanExecutDetail b ON a.ID = b.PlanExecutMainID

	IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#FinalData') AND TYPE='U') BEGIN DROP  TABLE #FinalData END;
	;WITH 
		FinalData AS 
		(
			SELECT TOP 0 a.*, b.IsRepair BadIsRepair, b.RepairTime, b.BadCreateBy, b.WorkPartName, b.ProcessingMode, --b.ProcedureName,
				CASE WHEN NOT EXISTS(SELECT 1 FROM #TbDtl WITH(NOLOCK) WHERE ID = a.ID AND OrderNum = a.OrderNum+1) AND IsPass = 1 THEN 1 ELSE 0 END IsFinish,
				(SELECT MAX(OrderNum) FROM #TbDtl WHERE ID = a.ID AND (IsPass = 1 OR IsRepair = 1)) NowOrderNum
			FROM #TbDtl a LEFT JOIN
				(
				--维修记录
				SELECT a.ID, a.OperatorDate, b.IsRepair, b.RepairTime, b.RepairUserID, b.ProcessingMode, b.WorkPartName, b.ProcedureName,
					ISNULL(ISNULL(c.ModifyBy, c.CreateBy), (SELECT UserName FROM dbo.syUser WHERE ID = b.RepairUserID))BadCreateBy ,
					ROW_NUMBER()OVER(PARTITION BY a.ID ORDER BY b.RepairTime DESC) RowNum --以最后一个未准
				FROM #TbDtl a LEFT JOIN dbo.qlBadAcquisition b ON a.InternalCode = b.BarCode AND a.ProcedureID = b.ProcedureID --AND a.OperatorDate < b.RepairTime
					LEFT JOIN dbo.mxqh_qlBadAcquisition c ON b.ID = c.BadId
				WHERE a.IsRepair = 1 AND b.IsNgLog = 0 AND CONVERT(DATETIME, a.OperatorDate)  < CONVERT(DATETIME, b.RepairTime)) b
				ON a.ID = b.ID AND b.RowNum = 1
		),
		FinalData2 AS 
		(
			SELECT a.ID, a.MOID, a.RouteID, a.TS, a.InternalCode, a.IsDump, a.ProcedureID, a.ProcedureName, a.OrderNum, a.OperatorDate, a.IsPass, a.IsRepair, a.BadIsRepair, a.CreateBy, a.OperatorID, a.RepairTime, 
				a.BadCreateBy, a.WorkPartName, a.ProcessingMode, a.IsFinish, a.NowOrderNum, 0 InNum, 0 FinishNum, 0 NotFinishNum,
				0 NgNum,	--在产不良，不包含历史不良
				0 RepairNum,				--在产已维修
				0 NotRepairNum,
				0 DumpNum
			FROM FinalData a
			WHERE a.OrderNum = a.NowOrderNum
		)
		SELECT b.WorkOrder, b.MaterialCode MateCode, b.MaterialName MateName, b.Quantity, b.TotalStartQty StartQuantity,
			a.RouteID, a.ID, a.TS, a.InternalCode, a.ProcedureID, a.ProcedureName, a.OperatorDate, a.CreateBy, a.OperatorID, --a.IsPass, a.IsRepair, a.IsDump, 
			a.InNum, FinishNum, NotFinishNum, NgNum, RepairNum, NotRepairNum, a.DumpNum,
			CASE WHEN a.IsDump = 1 THEN '报废' WHEN a.IsFinish= 1 THEN '完工' ELSE '在产' END Finish,
			CASE WHEN a.IsPass = 1 THEN '合格' WHEN a.IsPass = 0 AND a.IsRepair = 1 THEN '不良' END OpPass,
			CASE WHEN a.BadIsRepair = 1 THEN '已维修' WHEN a.IsRepair = 1 AND a.BadIsRepair != 1 THEN '待维修' END BadRepair, a.RepairTime, a.WorkPartName, 
			a.BadCreateBy, CASE a.ProcessingMode WHEN  '1' THEN '维修' WHEN '2' THEN '更换' WHEN '3' THEN '报废' END ProcessingMode, --处理方式   1 维修 2 更换 3报废
			'组装' ProType
		INTO #FinalData
		FROM FinalData2 a INNER JOIN dbo.mxqh_plAssemblyPlanDetail b ON a.MOID = b.ID
		WHERE ((a.IsFinish = 0 AND @IsNow = 1) OR @IsNow = 0)
		ORDER BY a.TS;

	--如果取到组装数据
	IF EXISTS(SELECT 1 FROM #TbMain)
	BEGIN
		--获取过站信息  ISNULL(ISNULL(b.ModifyBy, b.CreateBy), c.UserName)
		INSERT INTO #TbDtl(ID, MOID, RouteID, TS, InternalCode, IsDump, ProcedureID, ProcedureName, OrderNum, OperatorDate, IsPass, IsRepair, CreateBy, OperatorID)
		SELECT a.ID, a.MOID, a.RouteID, a.TS, a.InternalCode, a.IsDump, b.ProcedureID, b.ProcedureName, b.OrderNum, b.OperatorDate, b.IsPass, b.IsRepair, ISNULL(ISNULL(c.ModifyBy, c.CreateBy), (SELECT UserName FROM dbo.syUser WHERE ID = b.OperatorID)), b.OperatorID
		FROM #TbMain a INNER JOIN dbo.opPlanExecutDetail b ON a.ID = b.PlanExecutMainID LEFT JOIN dbo.mxqh_opPlanExecDetailLog c ON b.ID = c.DetalId
		WHERE b.ExtendOne = '0'
		UNION ALL
		SELECT a.ID, a.MOID, a.RouteID, a.TS, a.InternalCode, a.IsDump,b.ProcedureID, b.ProcedureName, b.OrderNum, b.OperatorDate, b.IsPass, b.IsRepair, ISNULL(ISNULL(c.ModifyBy, c.CreateBy), (SELECT UserName FROM dbo.syUser WHERE ID = b.OperatorID)), b.OperatorID
		FROM #TbMain a INNER JOIN au_mes_bak.dbo.opPlanExecutDetail_Back b ON a.ID = b.PlanExecutMainID LEFT JOIN dbo.mxqh_opPlanExecDetailLog c ON b.ID = c.DetalId
		WHERE b.ExtendOne = '0';

		;WITH 
		FinalData AS 
		(
			SELECT a.*, b.IsRepair BadIsRepair, b.RepairTime, b.BadCreateBy, b.WorkPartName, b.ProcessingMode, --b.ProcedureName,
				CASE WHEN NOT EXISTS(SELECT 1 FROM #TbDtl WITH(NOLOCK) WHERE ID = a.ID AND OrderNum = a.OrderNum+1) AND IsPass = 1 THEN 1 ELSE 0 END IsFinish,
				(SELECT MAX(OrderNum) FROM #TbDtl WHERE ID = a.ID AND (IsPass = 1 OR IsRepair = 1)) NowOrderNum
			FROM #TbDtl a LEFT JOIN
				(
				--维修记录
				SELECT a.ID, a.OperatorDate, b.IsRepair, b.RepairTime, b.RepairUserID, b.ProcessingMode, b.WorkPartName, b.ProcedureName,
					ISNULL(ISNULL(c.ModifyBy, c.CreateBy), (SELECT UserName FROM dbo.syUser WHERE ID = b.RepairUserID))BadCreateBy ,
					ROW_NUMBER()OVER(PARTITION BY a.ID ORDER BY b.RepairTime DESC) RowNum --以最后一个未准
				FROM #TbDtl a LEFT JOIN dbo.qlBadAcquisition b ON a.InternalCode = b.BarCode AND a.ProcedureID = b.ProcedureID --AND a.OperatorDate < b.RepairTime
					LEFT JOIN dbo.mxqh_qlBadAcquisition c ON b.ID = c.BadId
				WHERE a.IsRepair = 1 AND b.IsNgLog = 0 AND CONVERT(DATETIME, a.OperatorDate)  < CONVERT(DATETIME, b.RepairTime)) b
				ON a.ID = b.ID AND b.RowNum = 1
		),
		FinalData2 AS 
		(
			SELECT a.ID, a.MOID, a.RouteID, a.TS, a.InternalCode, a.IsDump, a.ProcedureID, a.ProcedureName, a.OrderNum, a.OperatorDate, a.IsPass, a.IsRepair, a.BadIsRepair, a.CreateBy, a.OperatorID, a.RepairTime, 
				a.BadCreateBy, a.WorkPartName, a.ProcessingMode, a.IsFinish, a.NowOrderNum,
				SUM(1)OVER(PARTITION BY a.MOID) InNum,
				ISNULL(SUM(CASE WHEN a.IsFinish= 1 THEN 1 ELSE 0 END)OVER(PARTITION BY a.MOID), 0) FinishNum,
				ISNULL(SUM(CASE WHEN a.IsFinish= 0 THEN 1 ELSE 0 END)OVER(PARTITION BY a.MOID), 0) NotFinishNum,
				ISNULL(SUM(CASE WHEN a.IsPass = 0 AND a.IsRepair = 1 THEN 1 ELSE 0 END)OVER(PARTITION BY a.MOID), 0) NgNum,	--在产不良，不包含历史不良
				ISNULL(SUM(CASE WHEN a.BadIsRepair = 1 THEN 1 ELSE 0 END)OVER(PARTITION BY a.MOID), 0) RepairNum,				--在产已维修
				ISNULL(SUM(CASE WHEN a.IsPass = 0 AND a.IsRepair = 1 AND a.BadIsRepair IS NULL THEN 1 ELSE 0 END)OVER(PARTITION BY a.MOID), 0) NotRepairNum,
				ISNULL(SUM(CASE WHEN a.IsDump= 1 THEN 1 ELSE 0 END)OVER(PARTITION BY a.MOID), 0) DumpNum
			FROM FinalData a
			WHERE a.OrderNum = a.NowOrderNum
		)
		INSERT INTO #FinalData		
		SELECT b.WorkOrder, b.MaterialCode MateCode, b.MaterialName MateName, b.Quantity, b.TotalStartQty StartQuantity,
			a.RouteID,a.ID, a.TS, a.InternalCode, a.ProcedureID, a.ProcedureName, a.OperatorDate, a.CreateBy, a.OperatorID, --a.IsPass, a.IsRepair, a.IsDump, 
			a.InNum, FinishNum, NotFinishNum, NgNum, RepairNum, NotRepairNum, a.DumpNum,
			CASE WHEN a.IsDump = 1 THEN '报废' WHEN a.IsFinish= 1 THEN '完工' ELSE '在产' END Finish,
			CASE WHEN a.IsPass = 1 THEN '合格' WHEN a.IsPass = 0 AND a.IsRepair = 1 THEN '不良' END OpPass,
			CASE WHEN a.BadIsRepair = 1 THEN '已维修' WHEN a.IsRepair = 1 AND a.BadIsRepair != 1 THEN '待维修' END BadRepair, a.RepairTime, a.WorkPartName, 
			a.BadCreateBy, CASE a.ProcessingMode WHEN  '1' THEN '维修' WHEN '2' THEN '更换' WHEN '3' THEN '报废' END ProcessingMode --处理方式   1 维修 2 更换 3报废
			, '组装'
		FROM FinalData2 a INNER JOIN dbo.mxqh_plAssemblyPlanDetail b ON a.MOID = b.ID
		WHERE ((a.IsFinish = 0 AND @IsNow = 1) OR @IsNow = 0)
		ORDER BY a.TS;

		TRUNCATE TABLE #TbMain
		TRUNCATE TABLE #TbDtl
	END

	--到后焊取数
	INSERT INTO #TbMain (a.ID, MOID, RouteID, TS, InternalCode, IsDump)
	SELECT a.ID, a.AssemblyPlanDetailID, a.RoutingID, a.TS, a.InternalCode, a.IsDump FROM dbo.opPlanExecutMainHH a WHERE AssemblyPlanDetailID IN  (SELECT ID FROM #TBORDER)
	UNION ALL
	SELECT a.ID, a.AssemblyPlanDetailID, a.RoutingID, a.TS, a.InternalCode, a.IsDump FROM au_mes_bak.dbo.opPlanExecutMainHH_Back a WHERE AssemblyPlanDetailID IN  (SELECT ID FROM #TBORDER)

	--如果取到后焊取数
	IF EXISTS(SELECT 1 FROM #TbMain)
	BEGIN
		--获取过站信息  ISNULL(ISNULL(b.ModifyBy, b.CreateBy), c.UserName)
		INSERT INTO #TbDtl(ID, MOID, RouteID, TS, InternalCode, IsDump, ProcedureID, ProcedureName, OrderNum, OperatorDate, IsPass, IsRepair, CreateBy, OperatorID)
		SELECT a.ID, a.MOID, a.RouteID, a.TS, a.InternalCode, a.IsDump, b.ProcedureID, b.ProcedureName, b.OrderNum, b.OperatorDate, b.IsPass, b.IsRepair, ISNULL(ISNULL(c.ModifyBy, c.CreateBy), (SELECT UserName FROM dbo.syUser WHERE ID = b.OperatorID)), b.OperatorID
		FROM #TbMain a INNER JOIN dbo.opPlanExecutDetailHH b ON a.ID = b.PlanExecutMainID LEFT JOIN dbo.mxqh_opPlanExecDetailLogHH c ON b.ID = c.DetalId
		WHERE b.ExtendOne = '0'
		UNION ALL
		SELECT a.ID, a.MOID, a.RouteID, a.TS, a.InternalCode, a.IsDump,b.ProcedureID, b.ProcedureName, b.OrderNum, b.OperatorDate, b.IsPass, b.IsRepair, ISNULL(ISNULL(c.ModifyBy, c.CreateBy), (SELECT UserName FROM dbo.syUser WHERE ID = b.OperatorID)), b.OperatorID
		FROM #TbMain a INNER JOIN au_mes_bak.dbo.opPlanExecutDetailHH_Back b ON a.ID = b.PlanExecutMainID LEFT JOIN dbo.mxqh_opPlanExecDetailLogHH c ON b.ID = c.DetalId
		WHERE b.ExtendOne = '0';

		WITH 
		FinalData AS 
		(
			SELECT a.*, b.IsRepair BadIsRepair, b.RepairTime, b.BadCreateBy, b.WorkPartName, b.ProcessingMode, --b.ProcedureName,
				CASE WHEN NOT EXISTS(SELECT 1 FROM #TbDtl WITH(NOLOCK) WHERE ID = a.ID AND OrderNum = a.OrderNum+1) AND IsPass = 1 THEN 1 ELSE 0 END IsFinish,
				(SELECT MAX(OrderNum) FROM #TbDtl WHERE ID = a.ID AND (IsPass = 1 OR IsRepair = 1)) NowOrderNum 
			FROM #TbDtl a LEFT JOIN
				(
				--维修记录
				SELECT a.ID, a.OperatorDate, b.IsRepair, b.RepairTime, b.RepairUserID, b.ProcessingMode, b.WorkPartName, b.ProcedureName,
					ISNULL(ISNULL(c.ModifyBy, c.CreateBy), (SELECT UserName FROM dbo.syUser WHERE ID = b.RepairUserID))BadCreateBy ,
					ROW_NUMBER()OVER(PARTITION BY a.ID ORDER BY b.RepairTime DESC) RowNum --以最后一个未准
				FROM #TbDtl a LEFT JOIN dbo.qlBadAcquisitionHH b ON a.InternalCode = b.BarCode AND a.ProcedureID = b.ProcedureID --AND a.OperatorDate < b.RepairTime
					LEFT JOIN dbo.mxqh_qlBadAcquisitionHH c ON b.ID = c.BadId
				WHERE a.IsRepair = 1 AND b.IsNgLog = 0 AND CONVERT(DATETIME, a.OperatorDate)  < CONVERT(DATETIME, b.RepairTime)) b
				ON a.ID = b.ID AND b.RowNum = 1
		),
		FinalData2 AS 
		(
			SELECT a.ID, a.MOID, a.RouteID, a.TS, a.InternalCode, a.IsDump, a.ProcedureID, a.ProcedureName, a.OrderNum, a.OperatorDate, a.IsPass, a.IsRepair, a.BadIsRepair, a.CreateBy, a.OperatorID, a.RepairTime, 
				a.BadCreateBy, a.WorkPartName, a.ProcessingMode, a.IsFinish, a.NowOrderNum,
				SUM(1)OVER(PARTITION BY a.MOID) InNum,
				ISNULL(SUM(CASE WHEN a.IsFinish= 1 THEN 1 ELSE 0 END)OVER(PARTITION BY a.MOID), 0) FinishNum,
				ISNULL(SUM(CASE WHEN a.IsFinish= 0 THEN 1 ELSE 0 END)OVER(PARTITION BY a.MOID), 0) NotFinishNum,
				ISNULL(SUM(CASE WHEN a.IsPass = 0 AND a.IsRepair = 1 THEN 1 ELSE 0 END)OVER(PARTITION BY a.MOID), 0) NgNum,	--在产不良，不包含历史不良
				ISNULL(SUM(CASE WHEN a.BadIsRepair = 1 THEN 1 ELSE 0 END)OVER(PARTITION BY a.MOID), 0) RepairNum,				--在产已维修
				ISNULL(SUM(CASE WHEN a.IsPass = 0 AND a.IsRepair = 1 AND a.BadIsRepair IS NULL THEN 1 ELSE 0 END)OVER(PARTITION BY a.MOID), 0) NotRepairNum,
				ISNULL(SUM(CASE WHEN a.IsDump= 1 THEN 1 ELSE 0 END)OVER(PARTITION BY a.MOID), 0) DumpNum  
			FROM FinalData a
			WHERE a.OrderNum = a.NowOrderNum
		)
		INSERT INTO #FinalData		
		SELECT b.WorkOrder, b.MaterialCode MateCode, b.MaterialName MateName, b.Quantity, b.TotalStartQty StartQuantity,
			a.RouteID, a.ID, a.TS, a.InternalCode, a.ProcedureID, a.ProcedureName, a.OperatorDate, a.CreateBy, a.OperatorID, --a.IsPass, a.IsRepair, a.IsDump,
			a.InNum, FinishNum, NotFinishNum, NgNum, RepairNum, NotRepairNum, DumpNum,
			CASE WHEN a.IsDump = 1 THEN '报废' WHEN a.IsFinish= 1 THEN '完工' ELSE '在产' END Finish,
			CASE WHEN a.IsPass = 1 THEN '合格' WHEN a.IsPass = 0 AND a.IsRepair = 1 THEN '不良' END OpPass,
			CASE WHEN a.BadIsRepair = 1 THEN '已维修' WHEN a.IsRepair = 1 AND a.BadIsRepair != 1 THEN '待维修' END BadRepair, a.RepairTime, a.WorkPartName, 
			a.BadCreateBy, CASE a.ProcessingMode WHEN  '1' THEN '维修' WHEN '2' THEN '更换' WHEN '3' THEN '报废' END ProcessingMode --处理方式   1 维修 2 更换 3报废
			, '后焊'
		FROM FinalData2 a INNER JOIN dbo.mxqh_plAssemblyPlanDetail b ON a.MOID = b.ID
		WHERE a.OrderNum = a.NowOrderNum AND ((a.IsFinish = 0 AND @IsNow = 1) OR @IsNow = 0)
		ORDER BY a.TS;
		TRUNCATE TABLE #TbMain
		TRUNCATE TABLE #TbDtl
	END


	--到包装取数
	INSERT INTO #TbMain (a.ID, MOID, RouteID, TS, InternalCode, IsDump)
	SELECT a.ID, a.AssemblyPlanDetailID, a.RoutingID, a.TS, a.InternalCode, a.IsDump FROM dbo.opPlanExecutMainPK a WHERE AssemblyPlanDetailID IN  (SELECT ID FROM #TBORDER)
	--如果取到后焊取数
	IF EXISTS(SELECT 1 FROM #TbMain)
	BEGIN
		--获取过站信息  ISNULL(ISNULL(b.ModifyBy, b.CreateBy), c.UserName)
		INSERT INTO #TbDtl(ID, MOID, RouteID, TS, InternalCode, IsDump, ProcedureID, ProcedureName, OrderNum, OperatorDate, IsPass, IsRepair, CreateBy, OperatorID)
		SELECT a.ID, a.MOID, a.RouteID, a.TS, a.InternalCode, a.IsDump, b.ProcedureID, b.ProcedureName, b.OrderNum, b.OperatorDate, b.IsPass, b.IsRepair, OperateBy, b.OperatorID
		FROM #TbMain a INNER JOIN dbo.opPlanExecutDetailPK b ON a.ID = b.PlanExecutMainID LEFT JOIN dbo.mxqh_opPlanExecDetailLog c ON b.ID = c.DetalId
		WHERE b.ExtendOne = '0';

		WITH 
		FinalData AS 
		(
			SELECT a.*, NULL BadIsRepair, NULL RepairTime, NULL BadCreateBy, NULL WorkPartName, NULL ProcessingMode, --b.ProcedureName,
				CASE WHEN NOT EXISTS(SELECT 1 FROM #TbDtl WITH(NOLOCK) WHERE ID = a.ID AND OrderNum = a.OrderNum+1) AND IsPass = 1 THEN 1 ELSE 0 END IsFinish,
				(SELECT MAX(OrderNum) FROM #TbDtl WHERE ID = a.ID AND (IsPass = 1 OR IsRepair = 1)) NowOrderNum 
			FROM #TbDtl a 
		),
		FinalData2 AS 
			(
				SELECT a.ID, a.MOID, a.RouteID, a.TS, a.InternalCode, a.IsDump, a.ProcedureID, a.ProcedureName, a.OrderNum, a.OperatorDate, a.IsPass, a.IsRepair, a.BadIsRepair, a.CreateBy, a.OperatorID, a.RepairTime, 
					a.BadCreateBy, a.WorkPartName, a.ProcessingMode, a.IsFinish, a.NowOrderNum,
					SUM(1)OVER(PARTITION BY a.MOID) InNum,
					ISNULL(SUM(CASE WHEN a.IsFinish= 1 THEN 1 ELSE 0 END)OVER(PARTITION BY a.MOID), 0) FinishNum,
					ISNULL(SUM(CASE WHEN a.IsFinish= 0 THEN 1 ELSE 0 END)OVER(PARTITION BY a.MOID), 0) NotFinishNum,
					ISNULL(SUM(CASE WHEN a.IsPass = 0 AND a.IsRepair = 1 THEN 1 ELSE 0 END)OVER(PARTITION BY a.MOID), 0) NgNum,	--在产不良，不包含历史不良
					ISNULL(SUM(CASE WHEN a.BadIsRepair = 1 THEN 1 ELSE 0 END)OVER(PARTITION BY a.MOID), 0) RepairNum,				--在产已维修
					ISNULL(SUM(CASE WHEN a.IsPass = 0 AND a.IsRepair = 1 AND a.BadIsRepair IS NULL THEN 1 ELSE 0 END)OVER(PARTITION BY a.MOID), 0) NotRepairNum,
					ISNULL(SUM(CASE WHEN a.IsDump= 1 THEN 1 ELSE 0 END)OVER(PARTITION BY a.MOID), 0) DumpNum
				FROM FinalData a
				WHERE a.OrderNum = a.NowOrderNum
			)
		INSERT INTO #FinalData
		SELECT b.WorkOrder, b.MaterialCode MateCode, b.MaterialName MateName, b.Quantity, b.TotalStartQty StartQuantity,
			a.RouteID, a.ID, a.TS, a.InternalCode, a.ProcedureID, a.ProcedureName, a.OperatorDate, a.CreateBy, a.OperatorID, --a.IsPass, a.IsRepair, a.IsDump, 
			a.InNum, FinishNum, NotFinishNum, NgNum, RepairNum, NotRepairNum, a.DumpNum,
			CASE WHEN a.IsDump = 1 THEN '报废' WHEN a.IsFinish= 1 THEN '完工' ELSE '在产' END Finish,
			CASE WHEN a.IsPass = 1 THEN '合格' WHEN a.IsPass = 0 AND a.IsRepair = 1 THEN '不良' END OpPass,
			CASE WHEN a.BadIsRepair = 1 THEN '已维修' WHEN a.IsRepair = 1 AND a.BadIsRepair != 1 THEN '待维修' END BadRepair, a.RepairTime, a.WorkPartName, 
			a.BadCreateBy, CASE a.ProcessingMode WHEN  '1' THEN '维修' WHEN '2' THEN '更换' WHEN '3' THEN '报废' END ProcessingMode --处理方式   1 维修 2 更换 3报废
			, '包装'
		FROM FinalData2 a INNER JOIN dbo.mxqh_plAssemblyPlanDetail b ON a.MOID = b.ID
		WHERE a.OrderNum = a.NowOrderNum AND ((a.IsFinish = 0 AND @IsNow = 1) OR @IsNow = 0)
		ORDER BY a.TS;
	END
	UPDATE #TempMO SET NeedRepairNum=[未处理维修] FROM (
	SELECT a.WorkOrder AS [工单], c.RouteName AS [工艺路由], a.ProType AS [生产阶段], 
		a.MateCode AS [料号], a.MateName AS [料名], CONVERT(NVARCHAR(20), a.Quantity) AS [工单数量], CONVERT(NVARCHAR(20), a.StartQuantity) AS [累计开工],
		CONVERT(NVARCHAR(20), a.InNum) AS [投入数],
		CONVERT(NVARCHAR(20), a.FinishNum) AS [完工数],CONVERT(NVARCHAR(20), a.NotFinishNum) AS [未完工数],
		CONVERT(NVARCHAR(20), a.NgNum) AS [不良数], CONVERT(NVARCHAR(20), a.RepairNum) AS [已处理维修],CONVERT(NVARCHAR(20), a.NotRepairNum) AS [未处理维修],
		CONVERT(NVARCHAR(20), a.DumpNum) AS [报废数],
		OperatorDate AS [最后操作时间]
	FROM (
	SELECT a.ProType, a.WorkOrder, a.RouteID, a.MateCode, a.MateName, a.Quantity, a.StartQuantity, a.InNum, a.FinishNum, a.NotFinishNum, a.NgNum, a.RepairNum, a.NotRepairNum, a.DumpNum,
		MAX(a.OperatorDate) OperatorDate
	FROM #FinalData a
	GROUP BY a.ProType, a.WorkOrder, a.RouteID,  a.MateCode, a.MateName, a.Quantity, a.StartQuantity, a.InNum, a.FinishNum, a.NotFinishNum, a.NgNum, a.RepairNum, a.NotRepairNum, a.DumpNum
	) a INNER JOIN dbo.boRouteMate b ON a.RouteID = b.ID INNER JOIN dbo.boRoute c ON b.RouteId = c.ID
	) t WHERE t.工单=#TempMO.WorkOrder
	
END 

IF EXISTS (SELECT 1 FROM tempdb.dbo.sysobjects WHERE id = OBJECT_ID(N'TEMPDB..#TempRate') AND type = 'U') 
BEGIN DROP TABLE #TempRate END;
CREATE TABLE #TempRate(WorkOrderID INT,Rate DECIMAL(18,4))
--获取直通率

;
WITH 
DtlData AS 
(
SELECT a.ID, PlanExecutMainID, ProcedureID, ProcedureName, OrderNum, OperatorDate
, a.TS, IsPass, IsRepair,b.AssemblyPlanDetailID,
DENSE_RANK()OVER(PARTITION BY PlanExecutMainID, ProcedureID ORDER BY a.ID DESC) InNumNo, --最后一笔资料
SUM(CONVERT(INT,a.IsRepair))OVER(PARTITION BY PlanExecutMainID, ProcedureID) HaveRepair --该工位是否有过维修
FROM dbo.opPlanExecutDetail a INNER JOIN dbo.opPlanExecutMain b ON a.PlanExecutMainID=b.ID
WHERE 1=1
AND b.AssemblyPlanDetailID IN (SELECT workOrderID FROM #TempMO)
AND a.OperatorDate BETWEEN @Date AND DATEADD(DAY,1,@Date)
),
Result AS
(
SELECT 
a.AssemblyPlanDetailID,a.ProcedureID,a.ProcedureName
,SUM(CASE WHEN a.IsPass=0 AND a.HaveRepair=0 THEN 0 ELSE 1 END )M
,SUM(CASE WHEN a.HaveRepair=0 THEN 0 ELSE 1 END )C
,CONVERT(DECIMAL(18,4),CASE WHEN SUM(CASE WHEN a.IsPass=0 AND a.HaveRepair=0 THEN 0 ELSE 1 END )=0 THEN 0 ELSE (SUM(CASE WHEN a.IsPass=0 AND a.HaveRepair=0 THEN 0 ELSE 1 END )-SUM(CASE WHEN a.HaveRepair=0 THEN 0 ELSE 1 END ))/CONVERT(DECIMAL(18,4),SUM(CASE WHEN a.IsPass=0 AND a.HaveRepair=0 THEN 0 ELSE 1 END )) END ) Rate
FROM DtlData a WHERE a.InNumNo = 1 
GROUP BY a.AssemblyPlanDetailID,a.ProcedureID,a.ProcedureName
) , 
DtlData1 AS 
(
SELECT a.ID, PlanExecutMainID, ProcedureID, ProcedureName, OrderNum, OperatorDate
, a.TS, IsPass, IsRepair,b.AssemblyPlanDetailID,
DENSE_RANK()OVER(PARTITION BY PlanExecutMainID, ProcedureID ORDER BY a.ID DESC) InNumNo, --最后一笔资料
SUM(CONVERT(int,a.IsRepair))OVER(PARTITION BY PlanExecutMainID, ProcedureID) HaveRepair --该工位是否有过维修
FROM dbo.opPlanExecutDetailHH a INNER JOIN dbo.opPlanExecutMainHH b ON a.PlanExecutMainID=b.ID
WHERE 1=1
AND a.OperatorDate BETWEEN @Date AND DATEADD(DAY,1,@Date)
AND b.AssemblyPlanDetailID IN (SELECT workOrderID FROM #TempMO)
),
Result1 AS
(
SELECT 
a.AssemblyPlanDetailID,a.ProcedureID,a.ProcedureName,SUM(CASE WHEN a.IsPass=0 AND a.HaveRepair=0 THEN 0 ELSE 1 END )M,SUM(CASE WHEN a.HaveRepair=0 THEN 0 ELSE 1 END )C
,CONVERT(DECIMAL(18,4),CASE WHEN SUM(CASE WHEN a.IsPass=0 AND a.HaveRepair=0 THEN 0 ELSE 1 END )=0 THEN 0 ELSE (SUM(CASE WHEN a.IsPass=0 AND a.HaveRepair=0 THEN 0 ELSE 1 END )-SUM(CASE WHEN a.HaveRepair=0 THEN 0 ELSE 1 END ))/CONVERT(DECIMAL(18,4),SUM(CASE WHEN a.IsPass=0 AND a.HaveRepair=0 THEN 0 ELSE 1 END )) END ) Rate
FROM DtlData1 a WHERE a.InNumNo = 1 
GROUP BY a.AssemblyPlanDetailID,a.ProcedureID,a.ProcedureName
), 
DtlData2 AS 
(
SELECT a.ID, PlanExecutMainID, ProcedureID, ProcedureName, OrderNum, OperatorDate
, a.TS, IsPass, IsRepair,b.AssemblyPlanDetailID,
DENSE_RANK()OVER(PARTITION BY PlanExecutMainID, ProcedureID ORDER BY a.ID DESC) InNumNo, --最后一笔资料
SUM(CONVERT(int,a.IsRepair))OVER(PARTITION BY PlanExecutMainID, ProcedureID) HaveRepair --该工位是否有过维修
FROM dbo.opPlanExecutDetailPK a INNER JOIN dbo.opPlanExecutMainPK b ON a.PlanExecutMainID=b.ID
WHERE 1=1
AND a.OperatorDate BETWEEN @Date AND DATEADD(DAY,1,@Date)
AND b.AssemblyPlanDetailID IN (SELECT workOrderID FROM #TempMO)
),
Result2 AS
(
SELECT 
a.AssemblyPlanDetailID,a.ProcedureID,a.ProcedureName,SUM(CASE WHEN a.IsPass=0 AND a.HaveRepair=0 THEN 0 ELSE 1 END )M,SUM(CASE WHEN a.HaveRepair=0 THEN 0 ELSE 1 END )C
,CONVERT(DECIMAL(18,4),CASE WHEN SUM(CASE WHEN a.IsPass=0 AND a.HaveRepair=0 THEN 0 ELSE 1 END )=0 THEN 0 ELSE (SUM(CASE WHEN a.IsPass=0 AND a.HaveRepair=0 THEN 0 ELSE 1 END )-SUM(CASE WHEN a.HaveRepair=0 THEN 0 ELSE 1 END ))/CONVERT(DECIMAL(18,4),SUM(CASE WHEN a.IsPass=0 AND a.HaveRepair=0 THEN 0 ELSE 1 END )) END ) Rate
FROM DtlData2 a WHERE a.InNumNo = 1 
GROUP BY a.AssemblyPlanDetailID,a.ProcedureID,a.ProcedureName
)
INSERT INTO #TempRate
SELECT t.AssemblyPlanDetailID,EXP(SUM(R))Rate FROM (
SELECT a.AssemblyPlanDetailID,CASE WHEN a.Rate=0 THEN 0 ELSE LOG(a.Rate)END R  FROM Result a
) t GROUP BY t.AssemblyPlanDetailID
UNION ALL
SELECT t.AssemblyPlanDetailID,EXP(SUM(R)) FROM (
SELECT a.AssemblyPlanDetailID,CASE WHEN a.Rate=0 THEN 0 ELSE LOG(a.Rate)END R  FROM Result1 a
) t GROUP BY t.AssemblyPlanDetailID
UNION ALL
SELECT t.AssemblyPlanDetailID,EXP(SUM(R)) FROM (
SELECT a.AssemblyPlanDetailID,CASE WHEN a.Rate=0 THEN 0 ELSE LOG(a.Rate)END R  FROM Result2 a
) t GROUP BY t.AssemblyPlanDetailID
 


;
WITH PlanData AS
(
SELECT * FROM #TempMO
),
MOArrange AS
(
SELECT a.ArrangeDate,a.WorkOrder,MAX(b.HrUserName)HrUserName,MAX(a.StandPerson)StandPerson
,MAX(a.ActPerson)ActPerson,MAX(a.NeedPerson)NeedPerson
,SUM(ISNULL(dbo.fun_CalStartHour(CONVERT(DATETIME,a.ArrangeDate+' '+a.StartTime),CONVERT(DATETIME,a.ArrangeDate+' '+a.EndTime),a.LineId),0))Times,MAX(a.LineId)LineId
,MAX(a.Remark)Remark
FROM dbo.mxqh_MoLineArrange a INNER JOIN dbo.mxqh_MoLineArrangeDtl b ON a.Id=b.ArrangeId
INNER JOIN #TempMO m ON a.WorkOrder=m.WorkOrder AND a.ArrangeDate=m.PlanDate
WHERE b.EmpType='L' AND a.ArrangeDate=@Date
GROUP BY a.ArrangeDate,a.WorkOrder
),
MOArrange2 AS
(
SELECT m.WorkOrderID,m.WorkOrder,SUM(ISNULL(dbo.fun_CalStartHour(CONVERT(DATETIME,a.ArrangeDate+' '+b.StartTime),CONVERT(DATETIME,a.ArrangeDate+' '+b.EndTime),a.LineId),0))PlanTime
FROM dbo.mxqh_MoLineArrange a INNER JOIN dbo.mxqh_MoLineArrangeDtl b ON a.Id=b.ArrangeId
INNER JOIN #TempMO m ON a.WorkOrder=m.WorkOrder AND a.ArrangeDate=m.PlanDate
WHERE b.EmpType NOT IN ('L','Z','W') AND a.ArrangeDate=@Date
GROUP BY m.WorkOrderID,m.WorkOrder
)
SELECT ISNULL(b1.Name,b.Name) LineName,ISNULL(ISNULL(ma.HrUserName,hr1.Name),hr.Name)Name
,a.PlanDate,w.WorkOrder,m.MaterialCode,m.MaterialName,m.Spec,w.Quantity,a.PlanCount,a.TotalPlanCount	
,ISNULL(a.NeedRepairNum,0)NeedRepairNum--待维修数量
,GETDATE() CopyDate
,ma2.plantime PlanTimes
,ma.Times--排产时间
,ma.NeedPerson StandPerson--标配人数取需求人数
,ma.ActPerson--实际人数
,CASE WHEN ISNULL(w.CompleteType,0)=0 THEN  com.FinishSum ELSE (SELECT SUM(t.CompleteQty) FROM dbo.mxqh_CompleteRpt t WHERE t.WorkOrderID=w.ID AND CONVERT(DATE,t.CreateDate)=@Date) END FinishSum --mes完工数量
,CASE WHEN ISNULL(w.CompleteType,0)=0 THEN r.Rate ELSE 1.00  END Rate,ISNULL(ma.Remark,'未排班')Remark
FROM PlanData a INNER JOIN dbo.mxqh_plAssemblyPlanDetail w ON a.WorkOrder=w.WorkOrder
INNER JOIN dbo.mxqh_Material m ON w.MaterialID=m.Id
LEFT JOIN MOArrange ma ON a.WorkOrder=ma.WorkOrder AND a.PlanDate=ma.ArrangeDate
LEFT JOIN MOArrange2 ma2 ON a.WorkOrder=ma2.WorkOrder
LEFT JOIN dbo.baAssemblyLine b ON a.LineId=b.ID
LEFT JOIN dbo.baAssemblyLine b1 ON ma.LineId=b1.ID
LEFT JOIN dbo.hr_User hr ON b.UserID=hr.Id
LEFT JOIN dbo.hr_User hr1 ON b1.UserID=hr1.Id
LEFT JOIN dbo.mx_PlanExBackNumMain com ON a.WorkOrderID=com.AssemblyPlanDetailID AND @Date=com.OpDate
LEFT JOIN #TempRate r ON a.WorkOrderID=r.WorkOrderID
ORDER BY LineName,Name


IF EXISTS (SELECT 1 FROM tempdb.dbo.sysobjects WHERE id = OBJECT_ID(N'TEMPDB..#TempMain') AND type = 'U') 
BEGIN DROP TABLE #TempMain END;
CREATE TABLE #TempMain(WorkOrderID INT,MainID INT,InternalCode VARCHAR(30))

IF EXISTS (SELECT 1 FROM tempdb.dbo.sysobjects WHERE id = OBJECT_ID(N'TEMPDB..#TempDtl') AND type = 'U') 
BEGIN DROP TABLE #TempDtl END;

INSERT INTO #TempMain  SELECT a.WorkOrderID,b.ID,b.InternalCode FROM #TempMO a INNER JOIN dbo.opPlanExecutMain b ON a.WorkOrderID=b.AssemblyPlanDetailID

SELECT b.WorkOrderID,b.MainID,b.InternalCode,c.ID,c.ProcedureID,c.ProcedureName,c.OrderNum,c.IsRepair,c.OperatorDate 
INTO #TempDtl 
--*
FROM #TempMain b
INNER JOIN dbo.opPlanExecutDetail c ON b.MainID=c.PlanExecutMainID
WHERE  c.OperatorDate BETWEEN @Date AND DATEADD(DAY,1,@Date)
AND ISNULL(c.PassTime,'')!=''

TRUNCATE TABLE #TempMain
INSERT INTO #TempMain  SELECT a.WorkOrderID,b.ID,b.InternalCode FROM #TempMO a INNER JOIN dbo.opPlanExecutMain b ON a.WorkOrderID=b.AssemblyPlanDetailID

INSERT INTO #TempDtl
SELECT b.WorkOrderID,b.MainID,b.InternalCode,c.ID,c.ProcedureID,c.ProcedureName,c.OrderNum,c.IsRepair,c.OperatorDate 
FROM #TempMain b
INNER JOIN dbo.opPlanExecutDetailHH c ON b.MainID=c.PlanExecutMainID
WHERE  c.OperatorDate BETWEEN @Date AND DATEADD(DAY,1,@Date)
AND ISNULL(c.PassTime,'')!=''

TRUNCATE TABLE #TempMain
INSERT INTO #TempMain  SELECT a.WorkOrderID,b.ID,b.InternalCode FROM #TempMO a INNER JOIN dbo.opPlanExecutMain b ON a.WorkOrderID=b.AssemblyPlanDetailID

INSERT INTO #TempDtl
SELECT b.WorkOrderID,b.MainID,b.InternalCode,c.ID,c.ProcedureID,c.ProcedureName,c.OrderNum,c.IsRepair,c.OperatorDate
FROM #TempMain b
INNER JOIN dbo.opPlanExecutDetailPK c ON b.MainID=c.PlanExecutMainID
WHERE  c.OperatorDate BETWEEN @Date AND DATEADD(DAY,1,@Date)
AND ISNULL(c.PassTime,'')!=''
SELECT a.*,b.WorkOrder FROM #TempDtl a INNER JOIN dbo.mxqh_plAssemblyPlanDetail b ON a.WorkOrderID=b.ID






END


