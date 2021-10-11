USE [au_mes]
GO
/****** Object:  StoredProcedure [dbo].[sp_TP_GetRDStoreSum]    Script Date: 2021/10/11 9:15:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[sp_TP_GetRDStoreSum]
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
	SELECT a.DocType,1 IsRcv,b.ID CID,a.ProjectCode,a.ProjectName,b.SNCode,b.InternalCode,b.CreateDate,b.MaterialID,b.MaterialCode,b.MaterialName,b.Status,b.Progress
	FROM dbo.TP_RDRcv a INNER JOIN dbo.TP_RDRcvDetail b ON a.ID=b.RcvID
	WHERE ISNULL(@MaterialID,b.MaterialID)=b.MaterialID
	),
	Ship AS
	(
	SELECT a.DocType,0 IsRcv,b.ID CID,a.ProjectCode,a.ProjectName,b.SNCode,b.InternalCode,b.CreateDate,b.MaterialID,b.MaterialCode,b.MaterialName,b.Status,b.Progress
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
	ROW_NUMBER()OVER(PARTITION BY a.SNCode,a.InternalCode ORDER BY a.CreateDate desc)RN
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
	SELECT a.Progress,a.MaterialCode,MIN(a.ProjectCode)ProjectCode,MIN(a.ProjectName)ProjectName,MIN(a.MaterialName)MaterialName,COUNT(1) Count
	,ISNULL((SELECT 	COUNT(1)	FROM FFResult t WHERE (ISNULL(t.Status,'')='报废' OR t.IsRcv=0)AND t.MaterialCode=a.MaterialCode AND ISNULL( t.Progress,0)=ISNULL(a.Progress,0) GROUP BY t.MaterialCode,t.Progress),0)UnAvaiable
	,ROW_NUMBER()OVER(ORDER BY MaterialCode)OrderNo
	FROM FFResult a GROUP BY a.MaterialCode,a.Progress
	) t  WHERE t.OrderNo>@beginIndex AND t.OrderNo<@endIndex
	




	;
	WITH Rcv AS
	(
	SELECT a.DocType,1 IsRcv,b.ID CID,b.SNCode,b.InternalCode,b.CreateDate,b.MaterialID,b.Status,b.Progress
	FROM dbo.TP_RDRcv a INNER JOIN dbo.TP_RDRcvDetail b ON a.ID=b.RcvID
	WHERE ISNULL(@MaterialID,b.MaterialID)=b.MaterialID
	),
	Ship AS
	(
	SELECT a.DocType,0 IsRcv,b.ID CID,b.SNCode,b.InternalCode,b.CreateDate,b.MaterialID,b.Status,b.Progress
	FROM dbo.TP_RDShip a INNER JOIN dbo.TP_RDShipDetail b ON a.ID=b.ShipID
	WHERE ISNULL(@MaterialID,b.MaterialID)=b.MaterialID
	),
	Result AS
	(
	SELECT * FROM Ship a 
	UNION ALL
	SELECT * FROM Rcv b 
	)
	SELECT COUNT(1)Count FROM (
	SELECT a.MaterialID FROM Result a GROUP BY a.MaterialID,a.Progress)t
	



END