ALTER PROC sp_PackDailyReport
(
@LineID INT,@MO_DocNo NVARCHAR(40),@SD DATETIME,@ED DATETIME
)
AS
BEGIN
	--DECLARE @LineID INT,@MO_DocNo NVARCHAR(40),@SD DATETIME='2019-1-20',@ED datetime	='2019-9-1'
	SET @MO_DocNo='%'+ISNULL(@MO_DocNo,'')+'%'
	--工单信息集合
	IF object_id('tempdb.dbo.#tempMO') is NULL
	BEGIN
		CREATE TABLE #tempMO(
		ID INT,
		WorkOrder NVARCHAR(40),
		MaterialCode NVARCHAR(60),
		MaterialName NVARCHAR(100),
		AssemblyLineName NVARCHAR(100)
		)
	END 
	ELSE
	BEGIN
		TRUNCATE TABLE #tempMO
	END 
	--投入SN集合
	IF object_id('tempdb.dbo.#tempSNCode') is NULL
	BEGIN
		CREATE TABLE #tempSNCode(
		ID INT,
		InputFlag INT 
		)
	END 
	ELSE
	BEGIN
		TRUNCATE TABLE #tempSNCode
	END 
	--工单包装箱号
	IF object_id('tempdb.dbo.#tempPackDetail') is NULL
	BEGIN
		CREATE TABLE #tempPackDetail(
		ID INT,
		PackDetailID INT 
		)
	END 
	ELSE
	BEGIN
		TRUNCATE TABLE #tempPackDetail
	END 
	--产出结果集合
	IF object_id('tempdb.dbo.#tempPackCode') is NULL
	BEGIN
		CREATE TABLE #tempPackCode(
		ID INT,
		OutputFlag INT 
		)
	END 
	ELSE
	BEGIN
		TRUNCATE TABLE #tempPackCode
	END 
	INSERT INTO #tempMO
	SELECT b.ID,b.WorkOrder,b.MaterialCode,b.MaterialName,d.Name
	FROM dbo.mxqh_plAssemblyPlanDetail b
	INNER JOIN dbo.mxqh_plAssemblyPlan c ON b.AssemblyPlanID=c.ID INNER JOIN dbo.baAssemblyLine d ON c.AssemblyLineID=d.ID
	WHERE d.ID=ISNULL(@LineID,d.ID) AND PATINDEX(@MO_DocNo,b.WorkOrder)>0

	--INSERT INTO #tempMO
	--SELECT b.ID,b.WorkOrder,b.MaterialCode,b.MaterialName,d.Name
	--FROM dbo.baInternalAndSNCode a INNER JOIN dbo.mxqh_plAssemblyPlanDetail b ON a.AssemblyPlanDetailID=b.ID
	--INNER JOIN dbo.mxqh_plAssemblyPlan c ON b.AssemblyPlanID=c.ID INNER JOIN dbo.baAssemblyLine d ON c.AssemblyLineID=d.ID
	--WHERE d.ID=ISNULL(@LineID,d.ID) AND PATINDEX(@MO_DocNo,b.WorkOrder)>0
	--AND a.TS>@SD AND a.TS<@ED
	--UNION    
	--SELECT d.ID,d.WorkOrder,d.MaterialCode,d.MaterialName,f.Name
	--FROM dbo.opPackageChild a INNER JOIN dbo.opPackageDetail b ON a.PackDetailID=b.ID
	--INNER JOIN dbo.opPackageMain c ON b.PackMainID=c.ID INNER JOIN dbo.mxqh_plAssemblyPlanDetail d ON c.AssemblyPlanDetailID=d.ID
	--INNER JOIN dbo.mxqh_plAssemblyPlan e ON d.AssemblyPlanID=e.ID INNER JOIN dbo.baAssemblyLine f ON e.AssemblyLineID=f.ID
	--WHERE d.ID=ISNULL(@LineID,f.ID) AND d.WorkOrder=ISNULL(@MO_DocNo,d.WorkOrder)
	--AND a.TS>@SD AND a.TS<@ED

	INSERT INTO #tempSNCode
	SELECT a.ID,CASE WHEN ISNULL(b.ID,'')='' THEN 0 ELSE 1 END InputFlag	
	FROM #tempMO a LEFT JOIN dbo.baInternalAndSNCode b  ON a.ID=b.AssemblyPlanDetailID AND b.TS>=@SD AND b.TS<@ED	

	INSERT INTO #tempPackDetail
	SELECT a.ID,d.ID PackDetailID
	FROM #tempMO a
	LEFT JOIN dbo.opPackageMain c ON a.ID=c.AssemblyPlanDetailID 
	LEFT JOIN dbo.opPackageDetail d ON c.ID=d.PackMainID

	INSERT INTO #tempPackCode
	SELECT a.ID,CASE WHEN ISNULL(b.ID,'')='' THEN 0 ELSE 1 END OutputFlag FROM #tempPackDetail a LEFT JOIN dbo.opPackageChild b ON a.PackDetailID=b.PackDetailID
	WHERE b.TS>=@SD AND b.TS<@ED

	SELECT a.*
	,(SELECT SUM(s.InputFlag) FROM #tempSNCode s WHERE s.ID=a.ID )InputQty
	,(SELECT SUM(p.OutputFlag) FROM #tempPackCode p WHERE p.ID=a.ID )OutPutQty
	FROM #tempMO a

END 