/*
获取模具生产信息明细
*/
ALTER PROC sp_GetMouldProductRepDetail
(
@MouldID INT,
@pageSize INT,
@pageIndex INT
)
AS
BEGIN
	DECLARE @beginIndex INT=@pageSize*(@pageIndex-1)
	DECLARE @endIndex INT=@pageSize*@pageIndex+1
	;
	WITH data1 AS
	(
	SELECT a.ID MouldID,m.id ItemID,b.UnitOutput,b.EffectiveDate,b.DisableDate,c.RCVQtyTU
	FROM mould a INNER JOIN dbo.Mould_ItemRelation b ON a.ID=b.MouldID INNER JOIN dbo.CBO_ItemMaster m ON b.ItemID=m.ID
	INNER JOIN dbo.Mould_RCV c ON b.ItemID=c.ItemID
	WHERE a.Deleted=0 AND b.Deleted=0 
	AND a.ID=2
	--AND c.ConfirmDate BETWEEN b.EffectiveDate AND b.DisableDate
	),
	SumData AS
	(
	SELECT a.MouldID,a.ItemID,SUM(a.RCVQtyTU)RcvQtySum FROM data1 a GROUP BY a.MouldID,a.ItemID
	),
	Result AS(
	SELECT b.Code,b.Name,b.SPECS,c.Code ItemCode,c.Name ItemName,c.SPECS ItemSPECS,a.RcvQtySum,b.Holder,
	ROW_NUMBER()OVER(ORDER BY b.Code,c.Code)RN
	FROM SumData a INNER JOIN dbo.Mould b ON a.MouldID=b.ID INNER JOIN dbo.CBO_ItemMaster c ON a.ItemID=c.ID
	)
	SELECT * FROM Result a WHERE a.RN>@beginIndex AND a.RN<@endIndex
	
	SELECT COUNT(*)Count FROM (
	SELECT DISTINCT a.code,c.code cc FROM dbo.Mould a INNER JOIN dbo.Mould_ItemRelation b ON a.ID=b.MouldID INNER JOIN dbo.CBO_ItemMaster c ON b.ItemID=c.ID
	INNER JOIN dbo.Mould_RCV d ON c.ID=d.ItemID
	WHERE a.Deleted=0 AND b.Deleted=0 AND a.ID=@MouldID
	) t
END 