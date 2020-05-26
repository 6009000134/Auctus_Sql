/*
研发库存汇总
*/
ALTER PROC sp_TP_GetRDStore
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
	SELECT a.ID,a.DocNo,a.DocType,1 IsRcv,b.ID CID,b.SNCode,b.CreateDate,b.MaterialID,b.MaterialCode,b.MaterialName,b.Status,b.Progress
	FROM dbo.TP_RDRcv a INNER JOIN dbo.TP_RDRcvDetail b ON a.ID=b.RcvID
	WHERE ISNULL(@MaterialID,b.MaterialID)=b.MaterialID
	),
	Ship AS
	(
	SELECT a.ID,a.DocNo,a.DocType,0 IsRcv,b.ID CID,b.SNCode,b.CreateDate,b.MaterialID,b.MaterialCode,b.MaterialName,b.Status,b.Progress
	FROM dbo.TP_RDShip a INNER JOIN dbo.TP_RDShipDetail b ON a.ID=b.ShipID
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
	,(SELECT 	COUNT(t.MaterialID)	FROM FFResult t WHERE t.MaterialID=a.MaterialID GROUP BY t.MaterialID)Total
	,ISNULL((SELECT 	COUNT(t.MaterialID)	FROM FFResult t WHERE (ISNULL(t.Status,'')='报废' OR t.IsRcv=0)AND t.MaterialID=a.MaterialID GROUP BY t.MaterialID),0)UnAvaiable
	,ROW_NUMBER()OVER(ORDER BY a.MaterialCode,a.CreateDate desc)OrderNo
	FROM FFResult a
	) t WHERE t.OrderNo>@beginIndex AND t.OrderNo<@endIndex




	;
	WITH Rcv AS
	(
	SELECT a.ID,a.DocNo,a.DocType,1 IsRcv,b.ID CID,b.SNCode,b.CreateDate,b.MaterialID,b.MaterialCode,b.MaterialName,b.Status,b.Progress
	FROM dbo.TP_RDRcv a INNER JOIN dbo.TP_RDRcvDetail b ON a.ID=b.RcvID
	WHERE ISNULL(@MaterialID,b.MaterialID)=b.MaterialID
	),
	Ship AS
	(
	SELECT a.ID,a.DocNo,a.DocType,0 IsRcv,b.ID CID,b.SNCode,b.CreateDate,b.MaterialID,b.MaterialCode,b.MaterialName,b.Status,b.Progress
	FROM dbo.TP_RDShip a INNER JOIN dbo.TP_RDShipDetail b ON a.ID=b.ShipID
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
	SELECT COUNT(a.ID)Count	FROM FFResult a
	



END 