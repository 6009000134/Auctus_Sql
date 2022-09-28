/*
修改完工报告
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
			DECLARE @Quantity INT--工单数量
			DECLARE @MesCompleteQty INT--修改后MES完工数量
			--工单数量
			SELECT @Quantity=b.Quantity FROM #TempTable a INNER JOIN dbo.mxqh_plAssemblyPlanDetail b ON a.WorkOrderID=b.ID
			--修改后MES完工数量
			SELECT @MesCompleteQty=SUM(t.CompleteQty) FROM (
			SELECT a.CompleteQty FROM #TempTable a
			UNION ALL            
			SELECT ISNULL(SUM(b.CompleteQty),0)CompleteQty FROM #TempTable a INNER JOIN dbo.mxqh_CompleteRpt b ON a.WorkOrderID=b.WorkOrderID 
			WHERE a.ID<>b.ID)t
			--校验完工总数是否大于工单数量
			IF @MesCompleteQty>@Quantity
			BEGIN
				SELECT '0'MsgType,'完工总数大于工单数量！' Msg			
				RETURN;
			END
			IF @MesCompleteQty>@TotalStartQty
			BEGIN
				SELECT '0'MsgType,'完工总数大于U9开工数量！' Msg			
				RETURN;
			END 
			--检验修改后完工数量是否小于U9中已经录入的完工数量
			IF @MesCompleteQty<@CompleteQty
			BEGIN
				SELECT '0'MsgType,'修改后完工总数不能小于U9已经录入的完工数量：'+CONVERT(VARCHAR(50),@CompleteQty) Msg
				RETURN;
			END          	
			UPDATE dbo.mxqh_CompleteRpt SET ModifyBy=@CreateBy,ModifyDate=GETDATE(),WorkOrderID=a.WorkOrderID,WorkOrder=a.WorkOrder,MaterialID=a.MaterialID,
			MaterialCode=a.MaterialCode,MaterialName=a.MaterialName,CompleteDate=a.CompleteDate,CompleteQty=a.CompleteQty
			FROM #TempTable a WHERE a.ID=dbo.mxqh_CompleteRpt.ID
			SELECT '1'MsgType,'修改成功！' Msg
		END 		
	END 
	ELSE
    BEGIN
		SELECT '0'MsgType,'修改失败！' Msg
	END 
END