/*
新增工单

--同一个主计划、序号（AssemblyPlanID,ListNo）唯一，不唯一则创建失败
--同一工单、同一条线只能有1个生产序号
--AssemblyDate和AssemblyLineID能确定一个主计划
2019-7-5
修改：工单不可重复
*/
ALTER PROC sp_AddMesPlanAndDetail
(
@CreateBy VARCHAR(50),--黄工平台会自动传入CreateBy，不需要自己去赋值
@ListNo VARCHAR(30)
)
AS
BEGIN
	DECLARE @PlanID INT--主计划ID
	DECLARE @IsExistsPlan INT--主计划是否存在
	DECLARE @IsNeedAddPlan INT=0--是否需要插入主计划数据
	DECLARE @IsNeedAddPlanDetail INT=0--是否需要插入工单详细数据
	IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#TempTable') AND TYPE='U')
	BEGIN		
		--工单或计划序号不可重复	
		IF EXISTS(SELECT 1 FROM #TempTable a,dbo.mxqh_plAssemblyPlanDetail b WHERE a.workorder=b.WorkOrder OR @ListNo=b.ListNo)
		BEGIN
			SELECT '0'MsgType,'添加失败，工单或计划序号不能重复！' Msg			
				RAISERROR('添加失败，工单或计划序号不能重复！。',16,1)
				RETURN;
		END 
		--计划序号不可重复
		
		--判断是否存在主计划ID
		SELECT @PlanID=a.ID FROM dbo.mxqh_plAssemblyPlan a,#TempTable b WHERE a.AssemblyDate=b.AssemblyDate AND a.AssemblyLineID=b.AssemblyLineID
			
		--判断是否存在主计划表记录
		IF ISNULL(@PlanID,0)>0
		BEGIN--存在主计划表记录
			IF EXISTS(SELECT 1 FROM dbo.mxqh_plAssemblyPlan a,dbo.mxqh_plAssemblyPlanDetail b,#TempTable c WHERE a.ID=@PlanID AND a.ID=b.AssemblyPlanID AND b.ListNo=c.ListNo)
			BEGIN
				SELECT '0'MsgType,'添加失败，计划序号必须唯一！' Msg							
				RAISERROR('添加失败，计划序号必须唯一。',16,1)
				RETURN;
			END 
			ELSE
            BEGIN				
				--插入工单详情数据	
				SET @IsNeedAddPlanDetail=1									
			END 
		END 
		ELSE--不存在主计划表记录，创建记录
        BEGIN
			--插入主计划数据
			SET @IsNeedAddPlan=1
			SET @IsNeedAddPlanDetail=1
		END 		
	END 
	ELSE
    BEGIN
		SELECT '0'MsgType,'添加失败！' Msg
		RAISERROR('添加失败。',16,1)
				RETURN;
	END 
	IF @IsNeedAddPlan=1
	BEGIN
			INSERT INTO dbo.mxqh_plAssemblyPlan
			        ( CreateBy ,			          CreateDate ,			          ModifyBy ,			          ModifyDate ,
			          AssemblyDate ,
			          AssemblyLineID ,
			          AssemblyLineCode ,
			          AssemblyLineName ,
			          VesionNo
			        )
			SELECT  @CreateBy ,GETDATE() ,@CreateBy ,GETDATE() ,a.AssemblyDate ,a.AssemblyLineID ,b.Code ,b.Name ,N'' 
			        FROM #TempTable a INNER JOIN dbo.baAssemblyLine b ON a.AssemblyLineID=b.ID			

			SELECT @PlanID=a.ID FROM dbo.mxqh_plAssemblyPlan a,#TempTable b WHERE a.AssemblyDate=b.AssemblyDate AND a.AssemblyLineID=b.AssemblyLineID
			--数据同步到Mes原表 plAssemblyPlan
			INSERT INTO dbo.plAssemblyPlan
			        ( ID ,TS ,AssemblyDate ,AssemblyLineID ,AssemblyLineCode ,AssemblyLineName ,CreateUserID ,CreateDate
			        )
					SELECT a.ID,a.CreateDate,a.AssemblyDate,a.AssemblyLineID,a.AssemblyLineCode,a.AssemblyLineName,1,a.CreateDate FROM dbo.mxqh_plAssemblyPlan a WHERE a.ID=@PlanID

	END 
	IF @IsNeedAddPlanDetail=1
	BEGIN
			--检查旧的物料表中是否有此料品信息，若没有，则从mxqh_bamaterial同步到baMaterial
			--IF NOT EXISTS(SELECT 1 FROM #TempTable a INNER JOIN dbo.baMaterial b ON a.MaterialID=b.ID)
			--BEGIN
			--	--SET IDENTITY_INSERT dbo.baMaterial ON 
			--	INSERT INTO dbo.baMaterial
			--	        ( ID ,TS ,MaterialTypeID ,MaterialCode ,MaterialName ,Brand ,Color ,LowerFPY ,Texture ,
			--	          IsBox ,Spec ,Unit ,Weight ,Remark ,IsCanChangePO ,PalletSumWight ,BoxWeight ,BoxCount ,PerBoxCount
			--			   ,ColorBoxCount ,PalletRoughWeight ,ColorBoxPrintNum ,UPPH ,PersonCount ,PassSwitch ,ProductSwitch
			--	        )
			--	SELECT a.ID,a.CreateDate,a.MaterialTypeID,a.MaterialCode,a.MaterialName,a.Brand,a.Color,a.LowerFPY,a.Texture,
			--	a.IsBox,a.Spec,a.Unit,a.Weight,a.Remark,a.IsCanChangePO,a.PalletSumWight,a.BoxWeight,a.BoxCount,a.PerBoxCount
			--	,a.ColorBoxCount,a.PalletRoughWeight,a.ColorBoxCount,a.UPPH,a.PersonCount,a.PassSwitch,a.ProductSwitch
			--	FROM dbo.mxqh_Material a,#TempTable b WHERE a.Id=b.MaterialID
			--	--SET IDENTITY_INSERT dbo.baMaterial OFF

			--END 
			--插入工单详情数据
			INSERT INTO dbo.mxqh_plAssemblyPlanDetail
			        ( CreateBy ,CreateDate ,ModifyBy ,ModifyDate ,AssemblyPlanID ,ListNo ,WorkOrder ,MaterialID ,MaterialCode ,MaterialName ,
			          Quantity ,OnlineTime ,OfflineTime ,CustomerOrder ,DeliveryDate ,CustomerID ,CustomerCode ,CustomerName ,SendPlaceID ,SendPlaceCode ,
			          SendPlaceName ,IsPublish ,IsLock ,Status ,CompleteDate ,ERPSO ,ERPQuantity ,IsUpload ,boRoutingID ,TBName ,CLName ,Remark,minWeight,maxWeight
					  ,CompleteType
			        )
			SELECT @CreateBy ,GETDATE() ,@CreateBy ,GETDATE() ,@PlanID ,@ListNo ,a.WorkOrder ,a.MaterialID ,a.MaterialCode ,a.MaterialName ,a.Quantity , 
			          N'' ,N'' ,a.CustomerOrder ,a.DeliveryDate ,a.CustomerID ,a.CustomerCode ,a.CustomerName ,c.ID ,c.Code ,c.Name ,1 ,0 ,0 ,NULL ,a.ERPSO , 
					  a.ERPQuantity ,0 ,a.boRoutingID ,a.TBName ,a.CLName ,a.Remark ,a.MinWeight,a.MaxWeight,a.CompleteType
			        FROM #TempTable a,dbo.baAssemblyLine b,dbo.baSendPlace c WHERE a.AssemblyLineID=b.ID AND a.SendPlaceID=c.ID			
			--数据同步到原表mxqh_plAssemblyPlanDetail
			INSERT INTO dbo.plAssemblyPlanDetail
			        ( ID ,TS ,AssemblyPlanID ,ListNo ,WorOrder ,MaterialID ,MaterialCode ,MaterialName ,Quantity ,OnlineTime ,OfflineTime ,
			          CustomerOrder ,DeliveryDate ,CustomerID ,CustomerCode ,CustomerName ,SendPlaceID ,SendPlaceCode ,SendPlaceName ,
			          IsPublish ,IsLock ,ExtendOne ,ExtendTwo ,ExtendThree ,ERPSO ,ERPMO ,ERPQuantity ,ERPOrderNo ,ERPOrderQty ,IsUpload			        )
			SELECT	a.ID,a.CreateDate ,a.AssemblyPlanID,@ListNo,a.WorkOrder,a.MaterialID,a.MaterialCode,a.MaterialName,a.Quantity,'','',
					a.CustomerOrder,a.DeliveryDate,a.CustomerID,a.CustomerCode,a.CustomerName,a.SendPlaceID,a.SendPlaceCode,a.SendPlaceName,
					a.IsPublish,a.IsLock,NULL,NULL,NULL,a.ERPSO,NULL,a.ERPQuantity,a.ERPOrderNo,a.ERPOrderQty,a.IsUpload
			        FROM dbo.mxqh_plAssemblyPlanDetail a ,#TempTable b WHERE a.WorkOrder=b.WorkOrder AND a.AssemblyPlanID=@PlanID
			SELECT '1'MsgType,'添加成功！' Msg	
	END 
END 

