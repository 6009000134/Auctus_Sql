/*
获取U9中工单的完工数量
*/
ALTER PROC sp_Auctus_Mes_GetMoCompleteQty
(
@WorkOrder VARCHAR(50)
)
AS
BEGIN
	SELECT SUM(ISNULL(a.CompleteQty,0))CompleteQty,SUM(ISNULL(a.RcvQtyByProductUOM,0))ActualRcvQty,MIN(ISNULL(b.TotalStartQty,0))TotalStartQty FROM dbo.MO_CompleteRpt a RIGHT JOIN dbo.MO_MO b ON a.MO=b.ID AND a.DocState IN (1,3)
	WHERE b.DocNo=@WorkOrder 
END 



