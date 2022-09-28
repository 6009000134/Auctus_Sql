/*
��ȡ�����ۼ��깤����
*/
ALTER PROC sp_GetTotalCompleteQty
(
@WorkOrderID int
)
AS
BEGIN
	--DECLARE @WorkOrderID INT

	--�ж���Ʒ�������Ƿ��й���
	IF EXISTS(SELECT 1 FROM dbo.opPlanExecutMain a WHERE a.AssemblyPlanDetailID=@WorkOrderID)--�й��չ������깤���������һ����������
	BEGIN	
			--�깤��Ϣ
		SELECT ISNULL(COUNT(t.IsPass),0)CompleteQty FROM 
		(
		SELECT c.IsPass,ROW_NUMBER()OVER(PARTITION BY a.InternalCode ORDER BY c.OrderNum desc)RN
		FROM dbo.opPlanExecutMain a INNER JOIN dbo.mxqh_plAssemblyPlanDetail b ON a.AssemblyPlanDetailID=b.ID
		INNER JOIN dbo.opPlanExecutDetail c ON a.ID=c.PlanExecutMainID
		WHERE b.ID=@WorkOrderID AND c.ExtendOne=0
		) t WHERE t.RN=1 AND t.IsPass=1	
	END 
	ELSE--û���չ������깤�������깤����
	BEGIN
		SELECT ISNULL(SUM(a.CompleteQty),0)CompleteQty FROM dbo.mxqh_CompleteRpt a WHERE a.WorkOrderID=@WorkOrderID
	END 
END 