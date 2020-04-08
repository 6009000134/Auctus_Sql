/*
获取模具生产信息
*/
ALTER PROC sp_GetMouldProductRep
(
@MouldCode VARCHAR(100),
@MouldName NVARCHAR(300),
@pageSize INT,
@pageIndex INT
)
AS
BEGIN
	DECLARE @beginIndex INT=@pageSize*(@pageIndex-1)
	DECLARE @endIndex INT=@pageSize*@pageIndex+1
	SET @MouldCode='%'+ISNULL(@MouldCode,'')+'%'
	SET @MouldName='%'+ISNULL(@MouldName,'')+'%'
	;
	WITH data1 AS
	(
	SELECT a.ID MouldID,m.id ItemID,b.UnitOutput,b.EffectiveDate,b.DisableDate,c.RCVQtyTU
	FROM mould a INNER JOIN dbo.Mould_ItemRelation b ON a.ID=b.MouldID INNER JOIN dbo.CBO_ItemMaster m ON b.ItemID=m.ID
	INNER JOIN dbo.Mould_RCV c ON b.ItemID=c.ItemID
	WHERE a.Deleted=0 AND b.Deleted=0 
	AND PATINDEX(@MouldCode,a.Code)>0 AND PATINDEX(@MouldName,a.Name)>0
	--AND c.ConfirmDate BETWEEN b.EffectiveDate AND b.DisableDate
	),
	SumData AS
	(
	SELECT a.MouldID,a.ItemID,SUM(a.RCVQtyTU)RcvQtySum FROM data1 a GROUP BY a.MouldID,a.ItemID
	),
	SumResult AS
	(
	SELECT a.MouldID,MAX(CEILING(a.RcvQtySum/b.UnitOutput))UsedNum FROM SumData a INNER JOIN dbo.Mould_ItemRelation b ON a.MouldID=b.MouldID AND b.ItemID=b.ItemID
	GROUP BY a.MouldID
	),
	Result AS
    (
	SELECT b.ID MouldID,b.Code,b.Name,b.SPECS,b.TotalNum,a.UsedNum,b.RemainNum,b.HoleNum,b.DailyCapacity,b.DailyNum,b.Holder,ROW_NUMBER()OVER(ORDER BY b.Code)RN
	FROM SumResult a INNER JOIN dbo.Mould b ON a.MouldID=b.ID
	)
	SELECT * FROM Result a WHERE a.RN>@beginIndex AND a.RN<@endIndex

	SELECT COUNT(*)Count FROM dbo.Mould a 
	WHERE a.Deleted=0 	AND PATINDEX(@MouldCode,a.Code)>0 AND PATINDEX(@MouldName,a.Name)>0

END 