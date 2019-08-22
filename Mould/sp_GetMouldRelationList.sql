
/*
获取模具料品信息列表
*/
ALTER PROC [dbo].[sp_GetMouldRelationList]
(
@pageSize INT,
@pageIndex INT,
@MouldCode VARCHAR(100),
@MouldName NVARCHAR(600)
)
AS
BEGIN
	DECLARE @beginIndex INT=@pageSize*(@pageIndex-1)
	DECLARE @endIndex INT=@pageSize*@pageIndex+1
	SET @MouldCode='%'+ISNULL(@MouldCode,'')+'%'
	SET @MouldName='%'+ISNULL(@MouldName,'')+'%'
	--获取分页数据
	SELECT * FROM (
	SELECT a.ID,a.MouldID,b.Code MouldCode,b.Name MouldName,b.SPECS MouldSPECS,a.ItemID,c.Code ItemCode,c.Name ItemName,c.SPECS ItemSPECS
	,a.UnitOutput,a.PoorRate,a.EffectiveDate,a.DisableDate,a.Remark
	,ROW_NUMBER()OVER(ORDER BY a.MouldCode) rn
	FROM dbo.Mould_ItemRelation a INNER JOIN dbo.Mould b ON a.MouldID=b.ID INNER JOIN dbo.CBO_ItemMaster c ON a.ItemID=c.ID	
	WHERE PATINDEX(@MouldCode,b.Code)>0 AND PATINDEX(@MouldName,b.Name)>0
	AND a.Deleted=0 AND b.Deleted=0
	) t
	WHERE  t.rn>@beginIndex AND t.rn<@endIndex
	--统计记录条数
	SELECT COUNT(1)Count
	FROM dbo.Mould_ItemRelation a INNER JOIN dbo.Mould b ON a.MouldID=b.ID INNER JOIN dbo.CBO_ItemMaster c ON a.ItemID=c.ID	
	WHERE PATINDEX(@MouldCode,b.Code)>0 AND PATINDEX(@MouldName,b.Name)>0
END 