alter PROC sp_GetQCCheckList
(
@size INT,
@index INT,
@CustomOrder VARCHAR(100),
@PalletCode VARCHAR(30),
@WorkOrder VARCHAR(30)
)
AS
BEGIN
		--DECLARE @size INT=10,
		--		@index INT=1,
		--		@CustomOrder VARCHAR(100),
		--		@PalletCode VARCHAR(30)='',
		--		@WorkOrder VARCHAR(30)='30190424013'
	DECLARE @beginIndex INT=@size*(@index-1)
	DECLARE @endIndex INT=@size*@index+1
	SET @CustomOrder='%'+ISNULL(@CustomOrder,'')+'%'
	SET @PalletCode='%'+ISNULL(@PalletCode,'')+'%'
	SET @WorkOrder='%'+ISNULL(@WorkOrder,'')+'%'
	SELECT * FROM(
	SELECT  ID,TS,DocNo,PalletCode,CustomOrder,CheckNum,CONVERT(VARCHAR(10),IsOK)IsOK,ProblemType,ProblemInfo,ProblemDesp,a.CheckTime,a.CheckUser
	,(SELECT DISTINCT t2.WorkOrder FROM dbo.opPackageDetail t,dbo.opPackageMain t1,dbo.mxqh_plAssemblyPlanDetail t2
	WHERE t.PalletCode=a.PalletCode AND t.PackMainID=t1.ID AND t1.AssemblyPlanDetailID=t2.ID
	AND PATINDEX(@PalletCode,t.PalletCode)>0
	)WorkOrder
	,ROW_NUMBER() OVER(ORDER by a.CheckTime DESC )RN
	,CONVERT(DECIMAL(18,2),ROUND(((SELECT COUNT(*) FROM dbo.qlCheckPar q WHERE q.MainID=a.ID AND q.IsCheckOk=1)/CONVERT(DECIMAL(18,4),(SELECT COUNT(*) FROM dbo.qlCheckPar q1 WHERE q1.MainID=a.ID)))*100,2))Rate
	FROM dbo.qlCheckMain a 
	WHERE PATINDEX(@PalletCode,a.PalletCode)>0 AND PATINDEX(@CustomOrder,a.CustomOrder)>0 
	)t
	WHERE t.RN>@beginIndex AND t.RN<@endIndex  AND PATINDEX(@WorkOrder,t.WorkOrder)>0  ORDER BY t.RN
	

	IF @WorkOrder='%%' AND @PalletCode='%%'
	BEGIN
    	SELECT COUNT(a.ID)Count
		FROM dbo.qlCheckMain a 
		WHERE PATINDEX(@PalletCode,a.PalletCode)>0 AND PATINDEX(@CustomOrder,a.CustomOrder)>0 
		AND a.PalletCode<>'190417027'	
	END 
	ELSE 
	BEGIN
		SELECT COUNT(*)Count FROM(
		SELECT  (SELECT DISTINCT t2.WorkOrder FROM dbo.opPackageDetail t,dbo.opPackageMain t1,dbo.mxqh_plAssemblyPlanDetail t2
		WHERE t.PalletCode=a.PalletCode AND t.PackMainID=t1.ID AND t1.AssemblyPlanDetailID=t2.ID
		AND PATINDEX(@PalletCode,t.PalletCode)>0 AND PATINDEX(@WorkOrder,t2.WorkOrder)>0
		)WorkOrder
		,ROW_NUMBER() OVER(ORDER by a.CheckTime )RN
		FROM dbo.qlCheckMain a 
		WHERE PATINDEX(@PalletCode,a.PalletCode)>0 AND PATINDEX(@CustomOrder,a.CustomOrder)>0 
		AND a.PalletCode<>'190417027'	
		)t WHERE PATINDEX(@WorkOrder,t.WorkOrder)>0 
	END 


	
END 

--SELECT *FROM dbo.opPackageDetail WHERE PalletCode='190417027'