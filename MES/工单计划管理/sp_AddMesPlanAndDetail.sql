/*
��������

--ͬһ�����ƻ�����ţ�AssemblyPlanID,ListNo��Ψһ����Ψһ�򴴽�ʧ��
--ͬһ������ͬһ����ֻ����1���������
--AssemblyDate��AssemblyLineID��ȷ��һ�����ƻ�
2019-7-5
�޸ģ����������ظ�
*/
ALTER PROC sp_AddMesPlanAndDetail
(
@CreateBy VARCHAR(50),--�ƹ�ƽ̨���Զ�����CreateBy������Ҫ�Լ�ȥ��ֵ
@ListNo VARCHAR(30)
)
AS
BEGIN
	DECLARE @PlanID INT--���ƻ�ID
	DECLARE @IsExistsPlan INT--���ƻ��Ƿ����
	DECLARE @IsNeedAddPlan INT=0--�Ƿ���Ҫ�������ƻ�����
	DECLARE @IsNeedAddPlanDetail INT=0--�Ƿ���Ҫ���빤����ϸ����
	IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#TempTable') AND TYPE='U')
	BEGIN		
		--������ƻ���Ų����ظ�	
		IF EXISTS(SELECT 1 FROM #TempTable a,dbo.mxqh_plAssemblyPlanDetail b WHERE a.workorder=b.WorkOrder OR @ListNo=b.ListNo)
		BEGIN
			SELECT '0'MsgType,'���ʧ�ܣ�������ƻ���Ų����ظ���' Msg			
				RAISERROR('���ʧ�ܣ�������ƻ���Ų����ظ�����',16,1)
				RETURN;
		END 
		--�ƻ���Ų����ظ�
		
		--�ж��Ƿ�������ƻ�ID
		SELECT @PlanID=a.ID FROM dbo.mxqh_plAssemblyPlan a,#TempTable b WHERE a.AssemblyDate=b.AssemblyDate AND a.AssemblyLineID=b.AssemblyLineID
			
		--�ж��Ƿ�������ƻ����¼
		IF ISNULL(@PlanID,0)>0
		BEGIN--�������ƻ����¼
			IF EXISTS(SELECT 1 FROM dbo.mxqh_plAssemblyPlan a,dbo.mxqh_plAssemblyPlanDetail b,#TempTable c WHERE a.ID=@PlanID AND a.ID=b.AssemblyPlanID AND b.ListNo=c.ListNo)
			BEGIN
				SELECT '0'MsgType,'���ʧ�ܣ��ƻ���ű���Ψһ��' Msg							
				RAISERROR('���ʧ�ܣ��ƻ���ű���Ψһ��',16,1)
				RETURN;
			END 
			ELSE
            BEGIN				
				--���빤����������	
				SET @IsNeedAddPlanDetail=1									
			END 
		END 
		ELSE--���������ƻ����¼��������¼
        BEGIN
			--�������ƻ�����
			SET @IsNeedAddPlan=1
			SET @IsNeedAddPlanDetail=1
		END 		
	END 
	ELSE
    BEGIN
		SELECT '0'MsgType,'���ʧ�ܣ�' Msg
		RAISERROR('���ʧ�ܡ�',16,1)
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
			--���빤����������
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
			SELECT '1'MsgType,'��ӳɹ���' Msg	
	END 
END 

