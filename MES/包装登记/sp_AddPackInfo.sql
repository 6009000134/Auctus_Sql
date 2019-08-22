Alter  PROC sp_AddPackInfo
(
@CreateBy VARCHAR(20)
)
AS
BEGIN

IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#TempTable') AND TYPE='U')
BEGIN	
	--PRINT '1'
	--插入opPackageMain主表数据
	INSERT INTO dbo.opPackageMain
	        ( ID ,TS ,AssemblyPlanDetailID ,PackListNo ,ProductID ,ProductCode ,ProductName ,CustomID ,CustomCode ,CustomName 
			,CustomPartNo ,SendPlaceID ,SendPlaceCode ,SendPlaceName ,PlanQuantity ,PerColorBoxQty ,PerBoxQuantity ,ShipForm
			,ShipInstruction ,MaxWeight ,MinWeight ,RadioKit ,Model ,Tanapa ,Ean ,PKGWT ,PKGID ,TransID ,CountryCode 
			--,UserGuide,Charger ,Antenna ,BeltClip ,Battery ,Descripition 
			,CreateUserID ,CreateDate)
			SELECT (SELECT MAX(ID)+1 FROM dbo.opPackageMain),GETDATE(),a.MoID,a.PackListNo
			,b.MaterialID,b.MaterialCode,b.MaterialName
			,b.CustomerID,b.CustomerCode,b.CustomerName,a.RadioKit--,a.CustomPartNo
			,b.SendPlaceID,b.SendPlaceCode,b.SendPlaceName
			,CONVERT(INT,b.Quantity)
			,CONVERT(INT,a.PerColorBoxQty),CONVERT(INT,a.PerBoxQuantity)
			,a.ShipForm,a.ShipInstruction
			,CONVERT(INT,a.MaxWeight),CONVERT(INT,a.MinWeight)
			,a.RadioKit,a.Model,a.Tanapa,a.Ean
			,CONVERT(INT,a.PKGWT)
			,a.PKGID+'+'+a.PackListNo,a.TransID,a.CountryCode,1,GETDATE()
			FROM #TempTable a	INNER JOIN dbo.mxqh_plAssemblyPlanDetail b  ON CONVERT(INT,a.MoID)=b.ID	
			
	--插入opPackageDetail箱号详情数据
	DECLARE @BoxNumber INT--箱号
	DECLARE @PackMainID INT --包装ID
	DECLARE @BoxCount INT,@PerBoxQuantity INT,@LoopCount INT=0,@Quantity INT=0
	SELECT @BoxNumber=MAX(e.BoxNumber) FROM dbo.mxqh_plAssemblyPlanDetail a,#TempTable b,mxqh_plAssemblyPlanDetail c,dbo.opPackageMain d,dbo.opPackageDetail e
	WHERE a.ID=b.MoID AND a.ERPSO=c.ERPSO AND ISNULL(a.ERPSO,'')<>'' AND c.ID=d.AssemblyPlanDetailID AND d.ID=e.PackMainID

	SELECT @Quantity=a.Quantity,@BoxCount=CEILING(a.Quantity/CONVERT(DECIMAL(18,2),c.PerBoxCount)),@PerBoxQuantity=c.PerBoxCount,@PackMainID=d.ID FROM dbo.mxqh_plAssemblyPlanDetail a,#TempTable b,dbo.baMaterial c,dbo.opPackageMain d WHERE a.ID=b.MoID AND a.MaterialID=c.ID AND a.ID=d.AssemblyPlanDetailID

	WHILE @LoopCount<@BoxCount
	BEGIN
		SET @LoopCount=@LoopCount+1
		SET @BoxNumber=ISNULL(@BoxNumber,0)+1
		INSERT INTO dbo.opPackageDetail
		        ( ID ,TS ,		          PackMainID ,		          BoxNumber ,
		          ProductCount ,		          Packweight ,		          PalletCode ,		          IsHasPrint
		        )
		VALUES  ( (SELECT MAX(ID)+1 FROM dbo.opPackageDetail), -- ID - int
		          GETDATE() , -- TS - datetime
		          @PackMainID, -- PackMainID - int
		          @BoxNumber, -- BoxNumber - int
		          CASE WHEN @LoopCount=@BoxCount THEN @Quantity-(@LoopCount-1)*@PerBoxQuantity ELSE @PerBoxQuantity END, -- ProductCount - int
		          NULL , -- Packweight - numeric(18, 2)
		          N'' , -- PalletCode - nvarchar(20)
		          0  -- IsHasPrint - bit
		        )
	END 

	----SELECT * FROM dbo.opPackageDetail
	----当填写了客户订单号的时候，修改工单上的客户订单号
	DECLARE @CustomerOrder NVARCHAR(100)
	SELECT @CustomerOrder=a.TransID FROM #TempTable a
	IF ISNULL(@CustomerOrder,'')<>''--客户订单号不为空，则将客户订单号更新到工单中
	BEGIN
		UPDATE dbo.mxqh_plAssemblyPlanDetail SET CustomerOrder=@CustomerOrder FROM #TempTable a WHERE a.MoID=dbo.mxqh_plAssemblyPlanDetail.ID
		UPDATE dbo.plAssemblyPlanDetail SET CustomerOrder=@CustomerOrder FROM #TempTable a WHERE a.MoID=dbo.plAssemblyPlanDetail.ID
	END 
	SELECT '1' MsgType,'新增成功！' Msg
	
END 

END 


