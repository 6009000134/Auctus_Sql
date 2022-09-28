/*
�޸��깤����
*/
ALTER PROCEDURE [dbo].[sp_UpdateCompleteRpt]
(
@CreateBy VARCHAR(30),
@CompleteQty INT,
@TotalStartQty INT
)
AS
BEGIN
	IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#TempTable') AND TYPE='U')
	BEGIN
        BEGIN
			DECLARE @Quantity INT--��������
			DECLARE @MesCompleteQty INT--�޸ĺ�MES�깤����
			--��������
			SELECT @Quantity=b.Quantity FROM #TempTable a INNER JOIN dbo.mxqh_plAssemblyPlanDetail b ON a.WorkOrderID=b.ID
			--�޸ĺ�MES�깤����
			SELECT @MesCompleteQty=SUM(t.CompleteQty) FROM (
			SELECT a.CompleteQty FROM #TempTable a
			UNION ALL            
			SELECT ISNULL(SUM(b.CompleteQty),0)CompleteQty FROM #TempTable a INNER JOIN dbo.mxqh_CompleteRpt b ON a.WorkOrderID=b.WorkOrderID 
			WHERE a.ID<>b.ID)t
			--У���깤�����Ƿ���ڹ�������
			IF @MesCompleteQty>@Quantity
			BEGIN
				SELECT '0'MsgType,'�깤�������ڹ���������' Msg			
				RETURN;
			END
			IF @MesCompleteQty>@TotalStartQty
			BEGIN
				SELECT '0'MsgType,'�깤��������U9����������' Msg			
				RETURN;
			END 
			--�����޸ĺ��깤�����Ƿ�С��U9���Ѿ�¼����깤����
			IF @MesCompleteQty<@CompleteQty
			BEGIN
				SELECT '0'MsgType,'�޸ĺ��깤��������С��U9�Ѿ�¼����깤������'+CONVERT(VARCHAR(50),@CompleteQty) Msg
				RETURN;
			END          	
			UPDATE dbo.mxqh_CompleteRpt SET ModifyBy=@CreateBy,ModifyDate=GETDATE(),WorkOrderID=a.WorkOrderID,WorkOrder=a.WorkOrder,MaterialID=a.MaterialID,
			MaterialCode=a.MaterialCode,MaterialName=a.MaterialName,CompleteDate=a.CompleteDate,CompleteQty=a.CompleteQty
			FROM #TempTable a WHERE a.ID=dbo.mxqh_CompleteRpt.ID
			SELECT '1'MsgType,'�޸ĳɹ���' Msg
		END 		
	END 
	ELSE
    BEGIN
		SELECT '0'MsgType,'�޸�ʧ�ܣ�' Msg
	END 
END