/*
QC登记详细信息
*/
Alter PROC sp_GetQCCheckDetail
(
@size INT,
@index INT,
@PalletCode VARCHAR(30)
)
AS
BEGIN
	--DECLARE @@size INT=10,
	--		@pageIndex INT=1,
	--		@CustomOrder VARCHAR(100),
	--		@PalletCode VARCHAR(30),
	--		@WorkOrder VARCHAR(30)
	DECLARE @beginIndex INT=@size*(@index-1)
	DECLARE @endIndex INT=@size*@index+1
	--判断是否存在栈板号
	IF EXISTS(SELECT 1 FROM dbo.opPackageDetail WHERE PalletCode=@PalletCode)--存在
    BEGIN
		--判断是否已经QC登记
		IF EXISTS(SELECT 1 FROM dbo.qlCheckMain WHERE PalletCode=@PalletCode)--已经登记过
		BEGIN
			SELECT '2' MsgType,'该栈板号已经检验过，是否再次检验！'Msg		    	
			--工单信息			
			SELECT TOP 1 a.WorkOrder,a.Quantity,a.CustomerOrder FROM dbo.mxqh_plAssemblyPlanDetail a INNER JOIN dbo.opPackageMain b ON a.ID=b.AssemblyPlanDetailID
			INNER JOIN dbo.opPackageDetail c ON b.ID=c.PackMainID
			WHERE c.PalletCode=@PalletCode
			
			SELECT ID,DocNo,PalletCode,CustomOrder,CheckNum,CONVERT(VARCHAR(2),IsOK)IsOK,ProblemType,ProblemInfo,ProblemDesp FROM dbo.qlCheckMain WHERE PalletCode=@PalletCode
		
			--登记信息详情
			SELECT b.ID,a.DocNo,b.MainID,b.SNCode,b.InternalCode,b.ProductCode,b.ProductName,b.IsCheckOk,b.Remark,b.Item1
			FROM dbo.qlCheckMain a INNER JOIN dbo.qlCheckPar b ON a.ID=b.MainID
			WHERE a.PalletCode=@PalletCode
		END 	
		ELSE--未登记过
        BEGIN
			SELECT '1' MsgType,'未登记过！'Msg
			--工单信息			
			SELECT TOP 1 a.WorkOrder,a.Quantity,a.CustomerOrder FROM dbo.mxqh_plAssemblyPlanDetail a INNER JOIN dbo.opPackageMain b ON a.ID=b.AssemblyPlanDetailID
			INNER JOIN dbo.opPackageDetail c ON b.ID=c.PackMainID
			WHERE c.PalletCode=@PalletCode
		END 
		
	END 
	ELSE--不存在
    BEGIN
		SELECT '0' MsgType,'栈板号不存在！'Msg
	END 
END 