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
		
	END 
	IF @IsNeedAddPlanDetail=1
	BEGIN
			--END 
			--插入工单详情数据
			INSERT INTO dbo.mxqh_plAssemblyPlanDetail
			        ( CreateBy ,CreateDate ,ModifyBy ,ModifyDate ,AssemblyPlanID ,ListNo ,WorkOrder ,MaterialID ,MaterialCode ,MaterialName ,
			          Quantity ,OnlineTime ,OfflineTime ,CustomerOrder ,DeliveryDate ,CustomerID ,CustomerCode ,CustomerName ,SendPlaceID ,SendPlaceCode ,
			          SendPlaceName ,IsPublish ,IsLock ,Status ,CompleteDate ,ERPSO ,ERPQuantity ,IsUpload ,boRoutingID ,TBName ,CLName ,Remark,minWeight,maxWeight
					  ,CompleteType,CustomerItemName,IsMR
			        )
			SELECT @CreateBy ,GETDATE() ,@CreateBy ,GETDATE() ,@PlanID ,@ListNo ,a.WorkOrder ,a.MaterialID ,a.MaterialCode ,a.MaterialName ,a.Quantity , 
			          N'' ,N'' ,a.CustomerOrder ,a.DeliveryDate ,a.CustomerID ,a.CustomerCode ,a.CustomerName ,c.ID ,c.Code ,c.Name ,1 ,0 ,0 ,NULL ,a.ERPSO , 
					  a.ERPQuantity ,0 ,a.boRoutingID ,a.TBName ,a.CLName ,a.Remark ,a.MinWeight,a.MaxWeight,a.CompleteType,a.CustomerItemName,a.IsMR
			        FROM #TempTable a,dbo.baAssemblyLine b,dbo.baSendPlace c WHERE a.AssemblyLineID=b.ID AND a.SendPlaceID=c.ID			
			SELECT '1'MsgType,'添加成功！' Msg	
	END 
END 

