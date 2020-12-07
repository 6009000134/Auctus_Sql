/*
获取机身标签打印记录
*/
create  PROC sp_GetBLLogList
(
@pageSize INT,
@pageIndex INT,
@SNCode NVARCHAR(100),
@CreatedBy nvarchar(100),
@WorkOrder nvarchar(100)
)
AS
BEGIN
DECLARE @beginIndex INT=@pageSize*(@pageIndex-1)
DECLARE @endIndex INT =@pageSize*@pageIndex+1
SET @SNCode='%'+ISNULL(@SNCode,'')+'%'
SET @CreatedBy='%'+ISNULL(@CreatedBy,'')+'%'
SET @WorkOrder='%'+ISNULL(@WorkOrder,'')+'%'
SELECT * FROM (
SELECT b.*,c.WorkOrder,c.MaterialCode,c.MaterialName,ROW_NUMBER() OVER(ORDER BY b.CreateDate desc) Rn
FROM dbo.opPlanExecutMain a INNER JOIN dbo.mxqh_BodyLabelPrintLog b ON a.InternalCode=b.SNCode
INNER JOIN dbo.mxqh_plAssemblyPlanDetail c ON a.AssemblyPlanDetailID=c.ID
WHERE 1=1
AND PATINDEX(@SNCode,b.SNCode)>0
AND PATINDEX(@CreatedBy,b.CreateBy)>0
AND PATINDEX(@WorkOrder,c.WorkOrder)>0
) t WHERE t.Rn>@beginIndex AND t.Rn<@endIndex


SELECT COUNT(1) Count
FROM dbo.opPlanExecutMain a INNER JOIN dbo.mxqh_BodyLabelPrintLog b ON a.InternalCode=b.SNCode
INNER JOIN dbo.mxqh_plAssemblyPlanDetail c ON a.AssemblyPlanDetailID=c.ID
WHERE 1=1
AND PATINDEX(@SNCode,b.SNCode)>0
AND PATINDEX(@CreatedBy,b.CreateBy)>0
AND PATINDEX(@WorkOrder,c.WorkOrder)>0
END 