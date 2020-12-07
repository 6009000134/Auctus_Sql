--查询工单设备信息
ALTER PROCEDURE [dbo].[sp_GetEquipMOList]
(
@PageSize INT,
@PageIndex INT,
@WorkOrder VARCHAR(300),
@Code VARCHAR(300),
@Name NVARCHAR(300)
)
AS
BEGIN
	DECLARE @beginIndex INT=(@PageIndex-1)*@PageSize
	DECLARE @endIndex INT=@PageIndex*@PageSize+1
	SET @Code='%'+ISNULL(@Code,'')+'%'
	SET @Name='%'+ISNULL(@Name,'')+'%'
	SET @WorkOrder='%'+ISNULL(@WorkOrder,'')+'%'
	SELECT * FROM (
	SELECT 
	a.ID,b.ID EquipID,c.ID WorkOrderID,c.WorkOrder,b.Code,b.Name,b.TypeID,b.TypeName,b.Type,a.LowerLimit,a.UpperLimit,b.CheckUOM,d.Name CheckUOMName,c.Remark
	,m.MaterialCode,m.MaterialName,c.Quantity
	,ROW_NUMBER() OVER(ORDER BY c.WorkOrder,b.Code)RN
	FROM 
	dbo.mxqh_EquipMoRelation a LEFT JOIN dbo.mxqh_Equipment b ON a.EquipID=b.ID
	LEFT JOIN dbo.mxqh_plAssemblyPlanDetail c ON a.WorkOrderID=c.ID
	LEFT JOIN dbo.mxqh_Material m ON c.MaterialID=m.Id
	LEFT JOIN dbo.mxqh_Base_Dic d ON b.CheckUOM=d.ID
	WHERE PATINDEX(@Code,b.Code)>0 AND PATINDEX(@Name,b.Name)>0 AND  PATINDEX(@WorkOrder,c.WorkOrder)>0
	) t WHERE t.RN>@beginIndex AND t.RN<@endIndex

	SELECT COUNT(1)Count
	FROM 
	dbo.mxqh_EquipMoRelation a LEFT JOIN dbo.mxqh_Equipment b ON a.EquipID=b.ID
	LEFT JOIN dbo.mxqh_plAssemblyPlanDetail c ON a.WorkOrderID=c.ID
	LEFT JOIN dbo.mxqh_Base_Dic d ON b.CheckUOM=d.ID
	WHERE PATINDEX(@Code,b.Code)>0 AND  PATINDEX(@Name,b.Name)>0 AND  PATINDEX(@WorkOrder,c.WorkOrder)>0

END
