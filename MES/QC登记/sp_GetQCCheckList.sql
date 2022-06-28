USE [au_mes]
GO
/****** Object:  StoredProcedure [dbo].[sp_GetQCCheckList]    Script Date: 2022/6/13 16:07:18 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[sp_GetQCCheckList]
(
@size INT,
@index INT,
@CustomOrder VARCHAR(100),
@PalletCode VARCHAR(30),
@WorkOrder VARCHAR(30)
,@VenNo							NVARCHAR(30)		--供应商编码
)
AS
BEGIN

	--获取系统默认供应商
	DECLARE @MOVenNo   NVARCHAR(30), --工单供应商
			@MainVenNo NVARCHAR(30) --系统默认供应商
	SELECT @MainVenNo  = ParaValue FROM dbo.SysPara WHERE ParaName = 'MainVenNo';
	SET @MainVenNo = ISNULL(@MainVenNo, '');

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
	SELECT t.*,CONVERT(BIT,CASE WHEN t1.OQCID IS NULL THEN 0 ELSE 1 END) HaveReport  FROM(
	SELECT  ID,TS,DocNo,PalletCode,CustomOrder,CheckNum,CONVERT(VARCHAR(10),IsOK)IsOK,ProblemType,ProblemInfo,ProblemDesp,a.CheckTime,a.CheckUser
	,(SELECT TOP 1 t2.WorkOrder FROM dbo.opPackageDetail t,dbo.opPackageMain t1,dbo.mxqh_plAssemblyPlanDetail t2
	WHERE t.PalletCode=a.PalletCode AND t.PackMainID=t1.ID AND t1.AssemblyPlanDetailID=t2.ID
	AND PATINDEX(@PalletCode,t.PalletCode)>0
	)WorkOrder
	,ROW_NUMBER() OVER(ORDER by a.CheckTime DESC )RN
	,CASE WHEN (SELECT COUNT(*) FROM dbo.qlCheckPar q1 WHERE q1.MainID=a.ID)=0 THEN 0 
	ELSE  CONVERT(DECIMAL(18,2),ROUND(((SELECT COUNT(*) FROM dbo.qlCheckPar q WHERE q.MainID=a.ID AND q.IsCheckOk=1)/CONVERT(DECIMAL(18,4),(SELECT COUNT(*) FROM dbo.qlCheckPar q1 WHERE q1.MainID=a.ID)))*100,2)) END Rate
	FROM dbo.qlCheckMain a 
	WHERE PATINDEX(@PalletCode,a.PalletCode)>0 AND PATINDEX(@CustomOrder,a.CustomOrder)>0 
	)t LEFT JOIN dbo.qc_OQCReport t1 ON t.ID=t1.OQCID
	   LEFT JOIN dbo.mxqh_plAssemblyPlanDetail d ON t.WorkOrder = d.WorkOrder
	WHERE t.RN>@beginIndex AND t.RN<@endIndex  AND PATINDEX(@WorkOrder,t.WorkOrder)>0  
		AND ((d.VenNo = @VenNo AND  ISNULL(@VenNo, '') != @MainVenNo) OR ISNULL(@VenNo, '') = '')
	ORDER BY t.RN
	

	IF @WorkOrder='%%' AND @PalletCode='%%'
	BEGIN
    	SELECT COUNT(t.PalletCode)Count FROM 
		(
		SELECT DISTINCT a.PalletCode,d.WorkOrder
		FROM dbo.qlCheckMain a left JOIN dbo.opPackageDetail b ON a.PalletCode=b.PalletCode
		left JOIN dbo.opPackageMain c ON b.PackMainID=c.ID left JOIN dbo.mxqh_plAssemblyPlanDetail d ON c.AssemblyPlanDetailID=d.ID
		WHERE PATINDEX(@CustomOrder,a.CustomOrder)>0 
		AND a.PalletCode<>'190417027'
		AND ((d.VenNo = @VenNo AND  ISNULL(@VenNo, '') != @MainVenNo) OR ISNULL(@VenNo, '') = '')
		)t	
	END 
	ELSE 
	BEGIN
		SELECT COUNT(*)Count FROM(
		SELECT  (SELECT TOP 1 t2.WorkOrder FROM dbo.opPackageDetail t,dbo.opPackageMain t1,dbo.mxqh_plAssemblyPlanDetail t2
		WHERE t.PalletCode=a.PalletCode AND t.PackMainID=t1.ID AND t1.AssemblyPlanDetailID=t2.ID
		AND PATINDEX(@PalletCode,t.PalletCode)>0 AND PATINDEX(@WorkOrder,t2.WorkOrder)>0
		)WorkOrder
		,ROW_NUMBER() OVER(ORDER by a.CheckTime )RN
		FROM dbo.qlCheckMain a 
		WHERE PATINDEX(@PalletCode,a.PalletCode)>0 AND PATINDEX(@CustomOrder,a.CustomOrder)>0 
		AND a.PalletCode<>'190417027'	
		)t  LEFT JOIN dbo.mxqh_plAssemblyPlanDetail d ON t.WorkOrder = d.WorkOrder
			
		WHERE PATINDEX(@WorkOrder,t.WorkOrder)>0  AND ((d.VenNo = @VenNo AND  ISNULL(@VenNo, '') != @MainVenNo) OR ISNULL(@VenNo, '') = '')
	END 


	
END 

--SELECT *FROM dbo.opPackageDetail WHERE PalletCode='190417027'