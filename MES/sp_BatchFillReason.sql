/*
批量填报工单延迟原因
*/
alter PROC sp_BatchFillReason
AS
BEGIN
	IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#TempTable') AND TYPE='U')
	BEGIN
		UPDATE dbo.u9_WorkOrderPlanDiffU9 SET Remark=a.Remark FROM #TempTable a WHERE u9_WorkOrderPlanDiffU9.DtlID=a.DtlID AND u9_WorkOrderPlanDiffU9.MainID=a.MainID
		SELECT '1'MsgType,'修改成功！'Msg
	END 
	ELSE
    BEGIN
		SELECT '0'MsgType,'传入数据错误！'Msg
	END 
END 