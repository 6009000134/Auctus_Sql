/*
新增工单

--同一个主计划、序号（AssemblyPlanID,ListNo）唯一，不唯一则创建失败
--同一工单、同一条线只能有1个生产序号
--AssemblyDate和AssemblyLineID能确定一个主计划
2019-7-5
修改：工单不可重复
*/
ALTER PROC sp_UpdateMesPlanAndDetail
(
@CreateBy VARCHAR(50)--黄工平台会自动传入CreateBy，不需要自己去赋值
)
AS
BEGIN

	DECLARE @PlanID INT--主计划ID
	DECLARE @IsExistsPlan INT--主计划是否存在
	DECLARE @IsExistsPlanDetail INT--同一条线工单是否唯一
	DECLARE @IsNeedAddPlan INT=0--是否需要更新主计划数据
	DECLARE @IsNeedAddPlanDetail INT=0--是否需要更新工单详细数据
	IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#TempTable') AND TYPE='U')
	BEGIN
		SELECT @PlanID=a.ID FROM dbo.mxqh_plAssemblyPlan a,#TempTable b WHERE a.AssemblyDate=b.AssemblyDate AND a.AssemblyLineID=b.AssemblyLineID

		--判断工单是否重复
		SELECT @IsExistsPlanDetail=COUNT(1) FROM #TempTable b,dbo.mxqh_plAssemblyPlanDetail c 
		WHERE  c.WorkOrder=b.WorkOrder 	AND c.ID<>b.ID--排除自身数据后进行对比
		IF ISNULL(@IsExistsPlanDetail,0)>0
		BEGIN
			SELECT '0'MsgType,'修改失败，工单不能重复！' Msg			
			RAISERROR('修改失败,工单不能重复。',16,1)
			RETURN;
		END 
				
		--判断是否存在主计划表记录
		IF ISNULL(@PlanID,0)>0
		BEGIN--存在主计划表记录
			IF EXISTS(SELECT 1 FROM dbo.mxqh_plAssemblyPlanDetail b,#TempTable c WHERE b.ListNo=c.ListNo AND b.ID<>c.ID)
			BEGIN				
				SELECT '0'MsgType,'修改失败，同一主计划中，计划序号必须唯一！' Msg							
				RAISERROR('修改失败,同一主计划中,计划序号必须唯一。',16,1)
				RETURN;
			END 
			ELSE
            BEGIN
				--更新工单详情
				SET @IsNeedAddPlanDetail=1						
			END 
		END 
		ELSE--不存在主计划表记录，创建记录
        BEGIN
			--插入主计划
			SET @IsNeedAddPlan=1
			--更新工单详情
			SET @IsNeedAddPlanDetail=1									
		END 		
	END 
	ELSE
    BEGIN
		SELECT '0'MsgType,'修改失败！' Msg
		RAISERROR('修改失败。',16,1)
		RETURN;
	END
	--插入主计划
	IF @IsNeedAddPlan=1
	BEGIN
			INSERT INTO dbo.mxqh_plAssemblyPlan
			        ( CreateBy ,CreateDate ,ModifyBy ,ModifyDate ,AssemblyDate ,AssemblyLineID ,AssemblyLineCode ,AssemblyLineName ,VesionNo
			        )
			SELECT  @CreateBy , -- CreateBy - varchar(30)
			          GETDATE() , -- CreateDate - datetime
			          @CreateBy , -- ModifyBy - varchar(30)
			          GETDATE() , -- ModifyDate - datetime
			          a.AssemblyDate , -- AssemblyDate - date
			          a.AssemblyLineID , -- AssemblyLineID - int
			          b.Code , -- AssemblyLineCode - nvarchar(10)
			          b.Name , -- AssemblyLineName - nvarchar(50)
			          N''  -- VesionNo - nvarchar(20)
			        FROM #TempTable a INNER JOIN dbo.baAssemblyLine b ON a.AssemblyLineID=b.ID

			SELECT @PlanID=a.ID FROM dbo.mxqh_plAssemblyPlan a,#TempTable b WHERE a.AssemblyDate=b.AssemblyDate AND a.AssemblyLineID=b.AssemblyLineID			

			--数据同步到Mes原表 plAssemblyPlan
			INSERT INTO dbo.plAssemblyPlan
			        ( ID ,TS ,AssemblyDate ,AssemblyLineID ,AssemblyLineCode ,AssemblyLineName ,CreateUserID ,CreateDate
			        )
					SELECT a.ID,a.CreateDate,a.AssemblyDate,a.AssemblyLineID,a.AssemblyLineCode,a.AssemblyLineName,1,a.CreateDate FROM dbo.mxqh_plAssemblyPlan a WHERE a.ID=@PlanID

	END  
	--更新工单详情
	IF @IsNeedAddPlanDetail=1
	BEGIN		
		UPDATE dbo.mxqh_plAssemblyPlanDetail 
		SET ModifyBy=@CreateBy,ModifyDate=GETDATE(),AssemblyPlanID=@PlanID,ListNo=a.ListNo
			--,WorkOrder=a.WorkOrder
			--,MaterialID=a.MaterialID,MaterialCode=a.MaterialCode,MaterialName=a.MaterialName
			,Quantity=a.Quantity
			,CustomerOrder=a.CustomerOrder
			,DeliveryDate=a.DeliveryDate
			--,CustomerID=a.CustomerID,CustomerCode=a.CUstomerCode,CustomerName=a.CustomerName
			,SendPlaceID=a.SendPlaceID,SendPlaceCode=b.Code,SendPlaceName=b.Name
			,ERPSO=a.ERPSO,ERPQuantity=a.ERPQuantity,boRoutingID=a.boRoutingID,TBName=a.TbName,CLName=a.ClName,Remark=a.Remark
			,MinWeight=a.MinWeight,MaxWeight=a.MaxWeight
			FROM #TempTable a,dbo.baSendPlace b WHERE a.ID=dbo.mxqh_plAssemblyPlanDetail.ID AND a.SendPlaceID=b.ID

		--同步数据到Mes原表 plAssemblyPlanDetail
		UPDATE dbo.plAssemblyPlanDetail 
		SET AssemblyPlanID=a.AssemblyPlanID,ListNo=a.ListNo
		--,WorOrder=a.WorkOrder
		--,MaterialID=a.MaterialID,MaterialCode=a.MaterialCode,MaterialName=a.MaterialName
		,Quantity=a.Quantity
		,CustomerOrder=b.CustomerOrder
		,DeliveryDate=a.DeliveryDate
		--,CustomerID=a.CustomerID,CustomerCode=a.CustomerCode,CustomerName=a.CustomerName
		,SendPlaceID=a.SendPlaceID,SendPlaceCode=a.SendPlaceCode,SendPlaceName=a.SendPlaceName
		--,IsPublish=a.IsPublish,IsLock=a.IsLock,ExtendOne=a.CompleteDate
		,ERPSO=a.ERPSO,ERPQuantity=a.ERPQuantity
		FROM dbo.mxqh_plAssemblyPlanDetail a,#TempTable b WHERE a.ID=b.ID AND dbo.plAssemblyPlanDetail.ID=a.ID
						
		SELECT '1'MsgType,'修改成功！' Msg
		--SELECT 	a.Quantity,a.CustomerOrder FROM #TempTable a,dbo.baSendPlace b WHERE a.SendPlaceID=b.ID	
	END 
END 


--SELECT *FROM temp0704
--SELECT * INTO temp07042 FROM #temptable
