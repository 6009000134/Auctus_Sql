/*
����������ӳ�ԭ��
*/
alter PROC sp_BatchFillReason
AS
BEGIN
	IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#TempTable') AND TYPE='U')
	BEGIN
		UPDATE dbo.u9_WorkOrderPlanDiffU9 SET Remark=a.Remark FROM #TempTable a WHERE u9_WorkOrderPlanDiffU9.DtlID=a.DtlID AND u9_WorkOrderPlanDiffU9.MainID=a.MainID
		SELECT '1'MsgType,'�޸ĳɹ���'Msg
	END 
	ELSE
    BEGIN
		SELECT '0'MsgType,'�������ݴ���'Msg
	END 
END 