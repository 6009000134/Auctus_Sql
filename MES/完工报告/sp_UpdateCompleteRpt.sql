/*
�޸��깤����
*/
ALTER  PROC sp_UpdateCompleteRpt
(
@CreateBy VARCHAR(30),
@CompleteQty INT
)
AS
BEGIN
	IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#TempTable') AND TYPE='U')
	BEGIN
        BEGIN
			--У���깤�����Ƿ���ڹ�������
			IF EXISTS (        
			SELECT 1 FROM 
			(
			SELECT a.WorkOrderID,a.CompleteQty FROM #TempTable a
			UNION ALL
			SELECT b.WorkOrderID,b.CompleteQty FROM #TempTable a INNER JOIN dbo.mxqh_CompleteRpt b ON a.workorderid=b.WorkOrderID AND b.ID<>a.ID
			) t LEFT JOIN dbo.mxqh_plAssemblyPlanDetail t1 ON t.WorkOrderID=t1.ID GROUP BY t.workorderID HAVING SUM(t.CompleteQty)>MIN(t1.Quantity)
			)
			BEGIN
				SELECT '0'MsgType,'�깤�������ڹ���������' Msg			
				RETURN;
			END
			--�����޸ĺ��깤�����Ƿ�С��U9���Ѿ�¼����깤����
			IF (SELECT SUM(a.CompleteQty) FROM dbo.mxqh_CompleteRpt a INNER JOIN #TempTable b ON a.WorkOrderID=b.WorkOrderID)<@CompleteQty
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

