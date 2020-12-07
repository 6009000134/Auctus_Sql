--查询设备点检数据
ALTER PROCEDURE [dbo].[sp_GetEquipmentCheckList]
(
@PageSize INT,
@PageIndex INT,
@SD DATETIME,
@ED DATETIME,
@EquipCode VARCHAR(300),
@EquipName NVARCHAR(300)
)
AS
BEGIN

SET @EquipCode='%'+ISNULL(@EquipCode,'')+'%'
SET @EquipName='%'+ISNULL(@EquipName,'')+'%'
IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#TempTable') AND TYPE='U')
BEGIN
	DROP TABLE #TempTable	
END 
IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#TempResult') AND TYPE='U')
BEGIN
	TRUNCATE TABLE #TempResult	
END 
ELSE
BEGIN
	CREATE TABLE #TempResult(
	[Index] INT,
	Duration VARCHAR(300),
	Record DECIMAL(18,4),
	WorkOrder VARCHAR(30),
	Code VARCHAR(30),
	Name VARCHAR(30),	
	CheckUOMName VARCHAR(30),
	LowerLimit DECIMAL(18,4),
	UpperLimit DECIMAL(18,4),
	CheckDate DATE
	)
END 
;
WITH data1 AS
(
SELECT FORMAT(a.CheckDate,'yyyy.MM.dd')+'-'+c.Name xAxis, a.CreateDate,a.Record,b.WorkOrder,c.Name Durantion,d.Code,d.Name,d.CheckUOM,e.Name CheckUOMName,c.OrderNo,a.CheckDate
,f.UpperLimit,f.LowerLimit
,ROW_NUMBER()OVER(PARTITION BY a.EquipID,a.WorkOrderID,a.CheckDate,c.Name ORDER BY d.Code,a.CheckDate,c.OrderNo,a.CreateDate DESC) rn
FROM dbo.mxqh_EquipCheck a INNER JOIN dbo.mxqh_plAssemblyPlanDetail b ON a.WorkOrderID=b.ID
INNER JOIN dbo.mxqh_Base_Dic c ON a.Duration=c.ID
INNER JOIN dbo.mxqh_Equipment d ON a.EquipID=d.ID
INNER JOIN dbo.mxqh_Base_Dic e ON d.CheckUOM=e.ID
INNER JOIN dbo.mxqh_EquipMoRelation f ON a.EquipID=f.EquipID AND a.WorkOrderID=f.WorkOrderID
WHERE a.CheckDate BETWEEN @SD AND @ED AND PATINDEX(@EquipCode,d.Code)>0 AND PATINDEX(@EquipName,d.Name)>0
)
SELECT * INTO #TempTable FROM 
data1 t WHERE t.rn=1
ORDER BY t.Code,t.CheckDate,t.OrderNo

--DECLARE @SD DATETIME='2020-3-2'
--DECLARE @ED DATETIME='2020-3-4'

IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#TempDuration') AND TYPE='U')
BEGIN
	TRUNCATE TABLE #TempDuration	
END 
ELSE
BEGIN
	CREATE TABLE #TempDuration
		(
		Duration VARCHAR(100)
		)
END 

;
WITH data1 AS
(
SELECT CONVERT(DATE,@SD)SD,CONVERT(DATE,@ED)ED
),
data2 AS
(
SELECT * FROM data1 a WHERE a.SD=@SD
UNION ALL
SELECT DATEADD(DAY,1,a.SD)SD,a.ED FROM data2 a INNER JOIN data1 b ON a.SD<b.ED
)
INSERT INTO #TempDuration
SELECT FORMAT(a.SD,'yyyy.MM.dd')+'-'+b.Name  FROM data2 a,(SELECT * FROM dbo.mxqh_Base_Dic t WHERE t.TypeName='时间段') b



--游标整理数据     
DECLARE @index INT=1
DECLARE @WorkOrder VARCHAR(50),@Name VARCHAR(100),@Code VARCHAR(100)
DECLARE cur CURSOR FOR 
SELECT DISTINCT WorkOrder,Name,Code FROM #TempTable     
OPEN cur     
FETCH NEXT FROM cur INTO @WorkOrder,@Name    ,@Code
WHILE @@FETCH_STATUS = 0
BEGIN       
	INSERT INTO #TempResult
    SELECT @index [Index],a.*,ISNULL(b.Record,0)Record,ISNULL(b.WorkOrder,@WorkOrder)WorkOrder,ISNULL(b.Code,@Code)Code,ISNULL(b.Name,@Name)Name,b.CheckUOMName 
	,b.LowerLimit,b.UpperLimit,b.CheckDate
	FROM #TempDuration a LEFT JOIN #TempTable b ON a.Duration=b.xAxis AND b.WorkOrder=@WorkOrder AND b.Name=@Name	 	 	
	SET @index=@index+1
    FETCH NEXT FROM cur INTO @WorkOrder,@Name,@Code
END
     
CLOSE cur
DEALLOCATE cur

SELECT DISTINCT Duration FROM #TempResult 

SELECT a.*,b.MaterialCode,b.MaterialName,b.Quantity FROM #TempResult a INNER JOIN dbo.mxqh_plAssemblyPlanDetail b ON a.WorkOrder=b.WorkOrder ORDER BY [Index]

SELECT DISTINCT [INDEX],UpperLimit,LowerLimit FROM #TempResult 
WHERE ISNULL(LowerLimit,-1)<>-1
ORDER BY [Index]

DECLARE @CheckUom VARCHAR(500)

SELECT @CheckUom=( SELECT DISTINCT t.CheckUOMName+'、' FROM 
#TempTable t FOR XML PATH(''))

SELECT @CheckUom CheckUOMName




END