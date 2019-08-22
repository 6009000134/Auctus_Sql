/*
��������

--ͬһ�����ƻ�����ţ�AssemblyPlanID,ListNo��Ψһ����Ψһ�򴴽�ʧ��
--ͬһ������ͬһ����ֻ����1���������
--AssemblyDate��AssemblyLineID��ȷ��һ�����ƻ�
2019-7-5
�޸ģ����������ظ�
*/
ALTER PROC sp_UpdateMesPlanAndDetail
(
@CreateBy VARCHAR(50)--�ƹ�ƽ̨���Զ�����CreateBy������Ҫ�Լ�ȥ��ֵ
)
AS
BEGIN

	DECLARE @PlanID INT--���ƻ�ID
	DECLARE @IsExistsPlan INT--���ƻ��Ƿ����
	DECLARE @IsExistsPlanDetail INT--ͬһ���߹����Ƿ�Ψһ
	DECLARE @IsNeedAddPlan INT=0--�Ƿ���Ҫ�������ƻ�����
	DECLARE @IsNeedAddPlanDetail INT=0--�Ƿ���Ҫ���¹�����ϸ����
	IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#TempTable') AND TYPE='U')
	BEGIN
		SELECT @PlanID=a.ID FROM dbo.mxqh_plAssemblyPlan a,#TempTable b WHERE a.AssemblyDate=b.AssemblyDate AND a.AssemblyLineID=b.AssemblyLineID

		--�жϹ����Ƿ��ظ�
		SELECT @IsExistsPlanDetail=COUNT(1) FROM #TempTable b,dbo.mxqh_plAssemblyPlanDetail c 
		WHERE  c.WorkOrder=b.WorkOrder 	AND c.ID<>b.ID--�ų��������ݺ���жԱ�
		IF ISNULL(@IsExistsPlanDetail,0)>0
		BEGIN
			SELECT '0'MsgType,'�޸�ʧ�ܣ����������ظ���' Msg			
			RAISERROR('�޸�ʧ��,���������ظ���',16,1)
			RETURN;
		END 
				
		--�ж��Ƿ�������ƻ����¼
		IF ISNULL(@PlanID,0)>0
		BEGIN--�������ƻ����¼
			IF EXISTS(SELECT 1 FROM dbo.mxqh_plAssemblyPlanDetail b,#TempTable c WHERE b.ListNo=c.ListNo AND b.ID<>c.ID)
			BEGIN				
				SELECT '0'MsgType,'�޸�ʧ�ܣ�ͬһ���ƻ��У��ƻ���ű���Ψһ��' Msg							
				RAISERROR('�޸�ʧ��,ͬһ���ƻ���,�ƻ���ű���Ψһ��',16,1)
				RETURN;
			END 
			ELSE
            BEGIN
				--���¹�������
				SET @IsNeedAddPlanDetail=1						
			END 
		END 
		ELSE--���������ƻ����¼��������¼
        BEGIN
			--�������ƻ�
			SET @IsNeedAddPlan=1
			--���¹�������
			SET @IsNeedAddPlanDetail=1									
		END 		
	END 
	ELSE
    BEGIN
		SELECT '0'MsgType,'�޸�ʧ�ܣ�' Msg
		RAISERROR('�޸�ʧ�ܡ�',16,1)
		RETURN;
	END
	--�������ƻ�
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

			--����ͬ����Mesԭ�� plAssemblyPlan
			INSERT INTO dbo.plAssemblyPlan
			        ( ID ,TS ,AssemblyDate ,AssemblyLineID ,AssemblyLineCode ,AssemblyLineName ,CreateUserID ,CreateDate
			        )
					SELECT a.ID,a.CreateDate,a.AssemblyDate,a.AssemblyLineID,a.AssemblyLineCode,a.AssemblyLineName,1,a.CreateDate FROM dbo.mxqh_plAssemblyPlan a WHERE a.ID=@PlanID

	END  
	--���¹�������
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

		--ͬ�����ݵ�Mesԭ�� plAssemblyPlanDetail
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
						
		SELECT '1'MsgType,'�޸ĳɹ���' Msg
		--SELECT 	a.Quantity,a.CustomerOrder FROM #TempTable a,dbo.baSendPlace b WHERE a.SendPlaceID=b.ID	
	END 
END 


--SELECT *FROM temp0704
--SELECT * INTO temp07042 FROM #temptable
