ALTER   PROC sp_UpdatePackInfo
(
@CreateBy VARCHAR(20)
)
AS
BEGIN

IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#TempTable') AND TYPE='U')
BEGIN	
	UPDATE dbo.opPackageMain SET TransID=a.TransID,ShipForm=a.ShipForm,ShipInstruction=a.ShipInstruction
	,CustomPartNo=a.CustomPartNo,MaxWeight=a.MaxWeight,MinWeight=a.MinWeight,CountryCode=a.CountryCode
	,Tanapa=a.Tanapa,Model=a.Model,PKGWT=a.PKGWT,RadioKit=a.RadioKit,Ean=a.Ean,PKGID=a.PKGID
	FROM #TempTable a WHERE a.ID=dbo.opPackageMain.ID
	
	UPDATE dbo.mxqh_plAssemblyPlanDetail SET CustomerOrder=a.TransID FROM #TempTable a WHERE a.AssemblyPlanDetailID=dbo.mxqh_plAssemblyPlanDetail.ID
	UPDATE dbo.plAssemblyPlanDetail SET CustomerOrder=a.TransID FROM #TempTable a WHERE a.AssemblyPlanDetailID=dbo.plAssemblyPlanDetail.ID
	SELECT '1' MsgType,'±à¼­³É¹¦£¡' Msg
END 

END 



--SELECT * from opPackageMain where AssemblyPlanDetailID = 1201

--SELECT * FROM dbo.baMaterial WHERE ID=475
