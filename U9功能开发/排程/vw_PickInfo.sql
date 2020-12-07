SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
GO

ALTER    VIEW vw_PickInfo
AS

WITH Itemmaster AS--MPS料品
(
SELECT a.ID,a.Code,a.Name
,b.MRPPlanningType--0/MPS件
,b.FixedLT--固定提前期
,ISNULL(c.Name,'')MRPCategory
FROM dbo.CBO_ItemMaster a LEFT JOIN dbo.CBO_MrpInfo b ON a.ID=b.ItemMaster
LEFT JOIN dbo.vw_MRPCategory c ON a.DescFlexField_PrivateDescSeg22=c.Code
WHERE a.ItemFormAttribute=10
),
PickInfo AS--订单信息
(
SELECT a.DocNo,a.ProductQty PQty,a.ItemMaster PID
,b.DocLineNO,b.ItemMaster CID,b.ActualReqQty CQty,b.IssuedQty,b.ActualReqQty-b.IssuedQty ReqQty
,b.IssuedQty-ISNULL((SELECT SUM(CompleteQty) FROM dbo.MO_CompleteRpt
	WHERE DocState IN (1,3) AND MO=a.ID),0)*b.ActualReqQty/a.ProductQty RemainIssuedQty
,b.ActualReqQty-b.IssuedQty RemainReqQty
,m1.Code,m1.Name,m1.MRPCategory
FROM vw_tempDocInfo a LEFT JOIN dbo.MO_MOPickList b ON a.ID=b.MO
INNER JOIN Itemmaster m ON a.Itemmaster=m.ID
INNER JOIN Itemmaster m1 ON b.ItemMaster=m1.ID
WHERE b.IssueStyle<>4-- AND a.DocNo='MO-30191216043'
UNION ALL
SELECT a.DocNo,a.ProductQty PQty,b.ItemInfo_ItemID,d.PickLineNo,d.ItemInfo_ItemID,d.ActualReqQty CQty,d.IssuedQty,d.ActualReqQty-d.IssuedQty ReqQty
,d.IssuedQty-ISNULL((SELECT sum(rcv.RcvQtyTU)
FROM dbo.PM_Receivement rec INNER JOIN dbo.PM_RcvLine rcv ON rec.ID=rcv.Receivement
WHERE rcv.SrcPO_SrcDocNo=a.DocNo AND rcv.SrcPO_SrcDocLineNo=b.DocLineNo AND rcv.Status=5),0)*d.ActualReqQty/a.ProductQty RemainIssuedQty
,d.ActualReqQty-d.IssuedQty RemainReqQty
,m1.Code,m1.Name,m1.MRPCategory
FROM vw_tempDocInfo a INNER JOIN dbo.PM_POLine b ON a.id=b.PurchaseOrder
INNER JOIN Itemmaster m ON b.ItemInfo_ItemID=m.ID
LEFT JOIN dbo.CBO_SCMPickHead c ON b.SCMPickHead=c.ID LEFT JOIN dbo.CBO_SCMPickList d ON d.PicKHead=c.ID
LEFT JOIN dbo.PM_POShipLine e ON e.POLine=b.ID
INNER JOIN Itemmaster m1 ON d.ItemInfo_ItemID=m1.ID
WHERE  b.Status in (0,1,2)  AND d.IssueStyle<>2
)
SELECT a.DocNo,a.PQty,a.PID,a.DocLineNO,a.CID,CONVERT(INT,a.CQty)CQty
,CONVERT(INT,a.IssuedQty)IssuedQty
,CONVERT(INT,a.ReqQty)ReqQty
,CONVERT(INT,a.RemainIssuedQty)RemainIssuedQty
,CONVERT(INT,a.RemainReqQty)RemainReqQty
,a.Code,a.Name,a.MRPCategory
FROM PickInfo a


GO

