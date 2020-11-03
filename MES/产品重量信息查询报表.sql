/*
��Ʒ������Ϣ��ѯ����
*/
alter PROC sp_SNWeightReport
(
@SD DATETime,
@ED DATETIME,
@SNCode VARCHAR(100),
@LineID INT,
@WorkOrder VARCHAR(100)
)
AS 
BEGIN 


--DECLARE @SD DATETIME='2019-05-01 00:00:00',@ED DATETIME='2019-07-19 23:59:59',@SNCode VARCHAR(100),@LineID INT,@WorkOrder VARCHAR(100)
--SET @WorkOrder='%'+ISNULL(@WorkOrder,'')+'%'
SET @SNCode='%'+ISNULL(@SNCode,'')+'%'
IF object_id('tempdb.dbo.#tempWeight') is NULL
BEGIN 
	CREATE TABLE #tempWeight(CreateDate DATETIME,Weight DECIMAL(18,2),SNCode VARCHAR(100))
END 
ELSE
BEGIN
	TRUNCATE TABLE #tempWeight
END		
 --SELECT * FROM dbo.mxqh_SnCodeWeigth
 IF ISNULL(@WorkOrder,'')='' AND ISNULL(@SNCode,'')=''
 BEGIN
	 INSERT INTO #tempWeight
	 SELECT a.CreateDate,a.Weigth,a.SNCode FROM dbo.mxqh_SnCodeWeigth a 
	 WHERE a.CreateDate between @SD AND @ED

	 SELECT FORMAT(a.CreateDate,'yyyy-MM-dd HH:mm:ss')CreateDate,a.Weight,a.SNCode,e.AssemblyLineName,d.WorkOrder,d.MaterialCode,d.MaterialName from #tempWeight as a  
							inner join baInternalAndSNCode as b on a.SNCode = b.SNCode 
							inner join dbo.opPlanExecutMainPK  as c on b.InternalCode = c.InternalCode
							inner join mxqh_plAssemblyPlanDetail as d on c.AssemblyPlanDetailID = d.ID
							inner join mxqh_plAssemblyPlan as e on d.AssemblyPlanID = e.ID   
							where ISNULL(@LineID,e.AssemblyLineID)=e.AssemblyLineID
							AND @WorkOrder=d.WorkOrder
							AND PATINDEX(@SNCode,a.SNCode)>0
 END 
 ELSE
 BEGIN

 SELECT FORMAT(a.CreateDate,'yyyy-MM-dd HH:mm:ss')CreateDate,a.Weigth Weight,a.SNCode,e.AssemblyLineName,d.WorkOrder,d.MaterialCode,d.MaterialName 
 FROM mxqh_SnCodeWeigth as a  
                        inner join baInternalAndSNCode as b on a.SNCode = b.SNCode 
                        inner join dbo.opPlanExecutMainPK  as c on b.InternalCode = c.InternalCode
                        inner join mxqh_plAssemblyPlanDetail as d on c.AssemblyPlanDetailID = d.ID
                        inner join mxqh_plAssemblyPlan as e on d.AssemblyPlanID = e.ID   
						where ISNULL(@LineID,e.AssemblyLineID)=e.AssemblyLineID
						AND @WorkOrder=d.WorkOrder
						AND PATINDEX(@SNCode,a.SNCode)>0
						AND a.CreateDate between @SD AND @ED
 END 

 
END 