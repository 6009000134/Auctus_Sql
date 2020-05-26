/*
商务中心库存明细
*/
ALTER PROC sp_TP_GetBCStoreDetail
(
@pageIndex INT=1,
@pageSize INT=10,
@MaterialID int,
@SNCode varchar(100),
@DocNo varchar(50)
)
AS
BEGIN

	;
	WITH data1 AS
	(
	SELECT 
	a.DocNo,a.DocType,a.Operator,a.RcvDate OpDate,NULL PlanReturnDate,a.ProjectCode,a.ProjectName,a.DeptCode,a.DeptName,a.Borrower,a.CustomerCode,a.CustomerName,a.Remark
	,b.SNCode,b.MaterialCode,b.MaterialName,b.Status,b.Progress,b.Remark LineRemark
	FROM dbo.TP_BCRcv a INNER JOIN dbo.TP_BCRcvDetail b ON a.ID=b.RcvID
	AND ISNULL(@SNCode,b.SNCode)=b.SNCode
	AND ISNULL(@MaterialID,b.MaterialID)=b.MaterialID
	AND ISNULL(@DocNo,a.DocNo)=a.DocNo
	UNION ALL
	SELECT 
	a.DocNo,a.DocType,a.Operator,a.DeliverDate OpDate,a.PlanReturnDate,'' ProjectCode,'' ProjectName,a.DeptCode,a.DeptName,a.Borrower,a.CustomerCode,a.CustomerName,a.Remark
	,b.SNCode,b.MaterialCode,b.MaterialName,b.Status,b.Progress,b.Remark LineRemark
	FROM dbo.TP_BCShip a INNER JOIN dbo.TP_BCShipDetail b ON a.ID=b.ShipID
	AND ISNULL(@SNCode,b.SNCode)=b.SNCode
	AND ISNULL(@MaterialID,b.MaterialID)=b.MaterialID
	AND ISNULL(@DocNo,a.DocNo)=a.DocNo
	)
	SELECT 
	*
	,ROW_NUMBER()OVER(ORDER BY data1.MaterialCode,data1.SNCode,data1.OpDate)RN
	FROM data1
END 