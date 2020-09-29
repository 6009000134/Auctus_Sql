/*
研发库存明细
*/
ALTER  PROC [dbo].[sp_TP_GetRDStoreDetail]
(
--DECLARE
@pageIndex INT=1,
@pageSize INT=10,
@MaterialID int,
@SNCode varchar(100),
@DocNo varchar(50)
)
AS
BEGIN
	DECLARE @beginIndex INT=@pageSize*(@pageIndex-1)
	DECLARE @endIndex INT=@pageSize*@pageIndex+1
	;
	WITH data1 AS
	(
	SELECT 
	a.DocNo,a.DocType,a.Operator,b.CreateDate OpDate,NULL PlanReturnDate,a.ProjectCode,a.ProjectName,a.DeptCode,a.DeptName,a.Borrower,a.CustomerCode,a.CustomerName,a.Remark
	,b.SNCode,b.MaterialCode,b.MaterialName,b.Status,b.Progress,b.Remark LineRemark
	,'1' IsRcv
	FROM dbo.TP_RDRcv a INNER JOIN dbo.TP_RDRcvDetail b ON a.ID=b.RcvID
	AND (ISNULL(@SNCode,b.SNCode)=b.SNCode OR ISNULL(@SNCode,'')=b.InternalCode)
	AND ISNULL(@MaterialID,b.MaterialID)=b.MaterialID
	AND ISNULL(@DocNo,a.DocNo)=a.DocNo
	UNION ALL
	SELECT 
	a.DocNo,a.DocType,a.Operator,b.CreateDate OpDate,a.PlanReturnDate,a.ProjectCode,a.ProjectName,a.DeptCode,a.DeptName,a.Borrower,a.CustomerCode,a.CustomerName,a.Remark
	,b.SNCode,b.MaterialCode,b.MaterialName,b.Status,b.Progress,b.Remark LineRemark
	,'0' IsRcv
	FROM dbo.TP_RDShip a INNER JOIN dbo.TP_RDShipDetail b ON a.ID=b.ShipID
	AND (ISNULL(@SNCode,b.SNCode)=b.SNCode OR ISNULL(@SNCode,'')=b.InternalCode)
	AND ISNULL(@MaterialID,b.MaterialID)=b.MaterialID
	AND ISNULL(@DocNo,a.DocNo)=a.DocNo
	)
	SELECT * FROM (
	SELECT 
	*
	,ROW_NUMBER()OVER(ORDER BY data1.MaterialCode,data1.SNCode,data1.OpDate)RN
	FROM data1) t WHERE t.RN>@beginIndex AND t.RN<@endIndex


		;
	WITH data1 AS
	(
	SELECT 
	a.DocNo
	FROM dbo.TP_RDRcv a INNER JOIN dbo.TP_RDRcvDetail b ON a.ID=b.RcvID
	AND (ISNULL(@SNCode,b.SNCode)=b.SNCode OR ISNULL(@SNCode,'')=b.InternalCode)
	AND ISNULL(@MaterialID,b.MaterialID)=b.MaterialID
	AND ISNULL(@DocNo,a.DocNo)=a.DocNo
	UNION ALL
	SELECT 
	a.DocNo
	FROM dbo.TP_RDShip a INNER JOIN dbo.TP_RDShipDetail b ON a.ID=b.ShipID
	AND (ISNULL(@SNCode,b.SNCode)=b.SNCode OR ISNULL(@SNCode,'')=b.InternalCode)
	AND ISNULL(@MaterialID,b.MaterialID)=b.MaterialID
	AND ISNULL(@DocNo,a.DocNo)=a.DocNo
	)
	SELECT COUNT(1)Count
	FROM data1
END 