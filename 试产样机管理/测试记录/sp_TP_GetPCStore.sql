/*
产品中心库存汇总
*/
ALTER PROC sp_TP_GetPCStore
(
@pageSize INT,
@pageIndex INT,
@MaterialID INT
)
AS
BEGIN	
	
	DECLARE @beginIndex INT=@pageSize*(@pageIndex-1)
	DECLARE @endIndex INT=@pageSize*@pageIndex+1
	
		;
	WITH Rcv AS
	(
	SELECT a.ID,a.DocNo,a.DocType,1 IsRcv,b.ID CID,b.SNCode,b.CreateDate,b.MaterialID,b.MaterialCode,b.MaterialName,b.Status,b.Progress,a.Borrower,a.DeptName,NULL PlanReturnDate
	FROM dbo.TP_PCRcv a INNER JOIN dbo.TP_PCRcvDetail b ON a.ID=b.RcvID
	WHERE ISNULL(@MaterialID,b.MaterialID)=b.MaterialID
	),
	Ship AS
	(
	SELECT a.ID,a.DocNo,a.DocType,0 IsRcv,b.ID CID,b.SNCode,b.CreateDate,b.MaterialID,b.MaterialCode,b.MaterialName,b.Status,b.Progress,a.Borrower,a.DeptName,a.PlanReturnDate
	FROM dbo.TP_PCShip a INNER JOIN dbo.TP_PCShipDetail b ON a.ID=b.ShipID
	WHERE ISNULL(@MaterialID,b.MaterialID)=b.MaterialID
	),
	Result AS
	(
	SELECT * FROM Ship a 
	UNION ALL
	SELECT * FROM Rcv b 
	),
	FResult AS
	(
	SELECT 
	*,
	ROW_NUMBER()OVER(PARTITION BY a.SNCode ORDER BY a.CreateDate desc)RN
	FROM Result a
	),
	FFResult AS
	(
	SELECT * 
	,CASE WHEN a.IsRcv=1 THEN '在库' 
	ELSE a.DocType END DocType3
	FROM FResult a WHERE a.RN=1
	)
	SELECT * FROM (
	SELECT *
	,ROW_NUMBER()OVER(ORDER BY a.MaterialCode,a.CreateDate desc)OrderNo
	FROM FFResult a
	) t WHERE t.OrderNo>@beginIndex AND t.OrderNo<@endIndex




	;
	WITH Rcv AS
	(
	SELECT a.ID,a.DocNo,a.DocType,1 IsRcv,b.ID CID,b.SNCode,b.CreateDate,b.MaterialID,b.MaterialCode,b.MaterialName,b.Status,b.Progress
	FROM dbo.TP_PCRcv a INNER JOIN dbo.TP_PCRcvDetail b ON a.ID=b.RcvID
	WHERE ISNULL(@MaterialID,b.MaterialID)=b.MaterialID
	),
	Ship AS
	(
	SELECT a.ID,a.DocNo,a.DocType,0 IsRcv,b.ID CID,b.SNCode,b.CreateDate,b.MaterialID,b.MaterialCode,b.MaterialName,b.Status,b.Progress
	FROM dbo.TP_PCShip a INNER JOIN dbo.TP_PCShipDetail b ON a.ID=b.ShipID
	WHERE ISNULL(@MaterialID,b.MaterialID)=b.MaterialID
	),
	Result AS
	(
	SELECT * FROM Ship a 
	UNION ALL
	SELECT * FROM Rcv b 
	),
	FResult AS
	(
	SELECT 
	*,
	ROW_NUMBER()OVER(PARTITION BY a.SNCode ORDER BY a.CreateDate desc)RN
	FROM Result a
	),
	FFResult AS
	(
	SELECT * 
	FROM FResult a WHERE a.RN=1
	)
	SELECT COUNT(a.ID)Count	FROM FFResult a
	



END 