/*
获取模具料品信息列表
*/
ALTER PROC [dbo].[sp_GetMouldRelationList]
(
@pageSize INT,
@pageIndex INT,
@MouldCode VARCHAR(100),
@MouldName NVARCHAR(600),
@ItemCode VARCHAR(100),
@ItemName NVARCHAR(300),
@Holder NVARCHAR(300),
@ModelType NVARCHAR(300)
)
AS
BEGIN
	DECLARE @beginIndex INT=@pageSize*(@pageIndex-1)
	DECLARE @endIndex INT=@pageSize*@pageIndex+1
	SET @MouldCode='%'+ISNULL(@MouldCode,'')+'%'
	SET @MouldName='%'+ISNULL(@MouldName,'')+'%'
	SET @ItemCode='%'+ISNULL(@ItemCode,'')+'%'
	SET @ItemName='%'+ISNULL(@ItemName,'')+'%'
	SET @MouldName='%'+ISNULL(@MouldName,'')+'%'
	SET @Holder='%'+ISNULL(@Holder,'')+'%'
	SET @ModelType='%'+ISNULL(@ModelType,'')+'%'
	--获取分页数据
	SELECT * FROM (
	SELECT a.ID,a.MouldID,b.Code MouldCode,b.Name MouldName,b.SPECS MouldSPECS,a.ItemID,a.ItemCode,a.ItemName,a.ItemSPECS
	,b.HoleNum,b.TotalNum,b.DailyCapacity,b.DailyNum,b.RemainNum,b.Holder,b.Manufacturer
	,b.CycleTime,b.ProductWeight,b.NozzleWeight,b.DealDate,b.EffectiveDate MouldEffective,b.MachineWeight,b.ModelType
	,a.UnitOutput,a.PoorRate,a.EffectiveDate,a.DisableDate,a.Remark
	,ROW_NUMBER()OVER(ORDER BY a.MouldCode) rn
	FROM dbo.Mould_ItemRelation a INNER JOIN dbo.Mould b ON a.MouldID=b.ID
	WHERE PATINDEX(@MouldCode,ISNULL(b.Code,''))>0 AND PATINDEX(@MouldName,b.Name)>0
	AND PATINDEX(@ItemCode,a.ItemCode)>0 	AND PATINDEX(@ItemName,a.ItemName)>0
	AND PATINDEX(@Holder,b.Holder)>0	AND PATINDEX(@ModelType,b.ModelType)>0
	AND a.Deleted=0 AND b.Deleted=0
	) t
	WHERE  t.rn>@beginIndex AND t.rn<@endIndex
	--统计记录条数
	SELECT COUNT(1)Count
	FROM dbo.Mould_ItemRelation a INNER JOIN dbo.Mould b ON a.MouldID=b.ID
	WHERE PATINDEX(@MouldCode,b.Code)>0 AND PATINDEX(@MouldName,b.Name)>0
	AND PATINDEX(@ItemCode,a.ItemCode)>0 	AND PATINDEX(@ItemName,a.ItemName)>0
	AND PATINDEX(@Holder,b.Holder)>0	AND PATINDEX(@ModelType,b.ModelType)>0
END 