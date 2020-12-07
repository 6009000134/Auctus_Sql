/*
打印机身标签
*/
ALTER PROC sp_GetBLPrintData
(
@BLCode NVARCHAR(25),
@IsRePrint VARCHAR(10)
)
AS
BEGIN
--EXEC sp_GetBLPrintData @BLCode='230300219470010'
--SELECT  *
--FROM    dbo.mxqh_BodyLabelPrintLog
--DECLARE @SNCode NVARCHAR(25)='GHP1487'
--SELECT @IsRePrint I

IF	ISNULL(@IsRePrint,'')='I'
BEGIN
	IF EXISTS(SELECT 1 FROM dbo.mxqh_BodyLabelPrintLog WHERE SNCode=@BLCode)
	BEGIN
		SELECT '0' MsgType,'【'+@BLCode+'】已打印！请使用补打印功能！' Msg
	END 
END 

IF EXISTS(SELECT 1 FROM dbo.opPlanExecutMain a WHERE a.InternalCode=@BLCode)
BEGIN
	SELECT '1' MsgType,'【'+@BLCode+'】打印成功！'Msg
	SELECT b.MaterialID,b.MaterialCode,b.MaterialName--,a.InternalCode,c.*,d.*
	,d.TemplateId,d.TS TemplateTime
	FROM dbo.opPlanExecutMain a,mxqh_plAssemblyPlanDetail b,dbo.baProductTemplate c ,dbo.vw_GetBarCodeTemplate d
	WHERE a.AssemblyPlanDetailID=b.ID AND b.MaterialID=c.ProductId AND c.TypeID=d.TypeID AND d.TypeID=9 --AND b.MaterialID=863--AND  a.InternalCode=@SNCode
	EXEC dbo.sp_GetMoReleaseSNPrint @MainId = N'', -- nvarchar(25)
    @WorkOrder = N'', -- nvarchar(50)
    @SNCode = 230300219470011, -- nvarchar(50)
    @Type = N'O', -- nvarchar(1)
    @Rprint = NULL -- bit
END 
ELSE
BEGIN 
	SELECT '0' MsgType, '此条码【'+@BLCode+'】'+'未上线！' Msg
END 

--SELECT * FROM dbo.mxqh_plAssemblyPlanDetail WHERE MaterialID=863

--4154

--SELECT *FROM opPlanExecutMain a WHERE a.InternalCode='GHP1487'
--INSERT INTO dbo.opPlanExecutMain
--SELECT (SELECT MAX(ID)+1 FROM dbo.opPlanExecutMain),4154,'TestSNCode',a.RoutingID,a.CreateUserID,GETDATE(),
--a.IsCrossRepair,a.RepairTimes,a.ExtendOne,a.ExtendTwo
--FROM opPlanExecutMain a WHERE a.InternalCode='GHP1487'

--UPDATE opPlanExecutMain SET CreateDate=FORMAT(GETDATE(),'yyyy-MM-dd HH:mm:ss') WHERE id=7537103


--230300219470010

	--SELECT * FROM dbo.mxqh_MoReleaseDtl




END 