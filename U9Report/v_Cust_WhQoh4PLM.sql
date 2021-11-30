ALTER VIEW v_Cust_WhQoh4PLM
AS
WITH data1 AS
(
SELECT 
b.Code,SUM(a.StoreQty )TotalStoreQty
FROM InvTrans_WhQoh a INNER JOIN dbo.CBO_ItemMaster b ON a.ItemInfo_ItemID=b.ID
GROUP BY b.Code
),
POData AS
(
SELECT a.DocNo,b.DocLineNo,c.SubLineNo
--,c.TotalRecievedQtyTU,c.TotalRtnFillQtyTU
,c.SupplierConfirmQtyTU,c.ItemInfo_ItemID
FROM dbo.PM_PurchaseOrder a INNER JOIN dbo.PM_POLine b ON a.ID=b.PurchaseOrder
INNER JOIN dbo.PM_POShipLine c ON b.ID=c.POLine
WHERE b.TotalRecievedQtyTU<b.SupplierConfirmQtyTU
AND a.STATUS NOT IN (0,3,4,5) AND b.STATUS NOT IN (0,3,4,5)
AND c.Status NOT IN (0,3,4,5)
--AND a.DocNo='PO20210616002'
),
RCVData AS
(
SELECT a.SrcDoc_SrcDocNo,a.SrcDoc_SrcDocLineNo,a.SrcDoc_SrcDocSubLineNo,SUM(a.RcvQtyTU)TotalRcvQtyTU
--,SUM(a.RtnFillQtyTU)TotalRtnFillQtyTU,SUM(a.RtnDeductQtyTU)TotalRtnDeductQtyTU
FROM pm_rcvline a 
--WHERE a.SrcDoc_SrcDocNo='PO20210616002'
GROUP BY a.SrcDoc_SrcDocNo,a.SrcDoc_SrcDocLineNo,a.SrcDoc_SrcDocSubLineNo
),
UNRcvData AS
(
SELECT 
--a.*,b.*
--a.DocNo,a.DocLineNo,a.SubLineNo--,a.TotalRecievedQtyTU
m.Code,SUM(a.SupplierConfirmQtyTU)TotalPurQty,SUM(ISNULL(b.TotalRcvQtyTU,0))TotalRcvQtyTU
--,b.TotalRtnFillQtyTU,b.TotalRtnDeductQtyTU
FROM POData a INNER JOIN dbo.CBO_ItemMaster m ON a.ItemInfo_ItemID=m.ID LEFT JOIN RCVData b ON a.DocNo=b.SrcDoc_SrcDocNo AND a.DocLineNo=b.SrcDoc_SrcDocLineNo AND a.SubLineNo=b.SrcDoc_SrcDocSubLineNo
WHERE a.SupplierConfirmQtyTU>b.TotalRcvQtyTU
GROUP BY m.Code
)
SELECT a.Code,a.TotalStoreQty--,b.TotalPurQty,b.TotalRcvQtyTU
,b.TotalPurQty-b.TotalRcvQtyTU UnRcvQty
FROM data1 a LEFT JOIN UNRcvData b ON a.Code=b.Code

