/*
工单投板记录查询
*/
CREATE PROC sp_WorkInputReport
(
@WorkOrder VARCHAR(50)
)
AS
BEGIN
--DECLARE @WorkOrder VARCHAR(50)
IF ISNULL(@WorkOrder,'')=''
SET @WorkOrder='AMO-30190620004'

SET @WorkOrder='%'+ISNULL(@WorkOrder,'')+'%'

SELECT a.WorkOrder,b.InternalCode,b.CreateDate,c.SNCode
FROM dbo.mxqh_plAssemblyPlanDetail a LEFT join dbo.opPlanExecutMain b ON a.ID=b.AssemblyPlanDetailID
LEFT  JOIN dbo.baInternalAndSNCode c ON b.InternalCode=c.InternalCode
WHERE PATINDEX(@WorkOrder,a.WorkOrder)>0

END 