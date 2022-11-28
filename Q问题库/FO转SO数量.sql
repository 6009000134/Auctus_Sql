;
WITH fodata AS
(
SELECT a.DocNo,b.DocLineNo,b.Num,b.ItemInfo_ItemCode,m.Name,m.SPECS,b.Status FROM dbo.SM_ForecastOrder a INNER JOIN dbo.SM_ForecastOrderLine b ON a.ID=b.ForecastOrder
INNER JOIN dbo.CBO_ItemMaster m ON b.ItemInfo_ItemID=m.ID
WHERE a.BusinessDate<=GETDATE() AND a.BusinessDate>=DATEADD(YEAR,-3,GETDATE())
),
SOData AS
(
SELECT 
b.SrcDocNo,b.SrcDocLineNo,SUM(b.OrderByQtyTU)SOQty
FROM dbo.SM_SO a INNER JOIN dbo.SM_SOLine b ON a.ID=b.SO
WHERE b.SrcDocNo LIKE 'FO%'
GROUP BY b.SrcDocLineNo,b.SrcDocNo
)
SELECT * 
FROM fodata a LEFT JOIN SOData b ON a.DocNo=b.SrcDocNo AND a.DocLineNo=b.SrcDocLineNo
WHERE a.Num>b.SOQty
ORDER BY a.DocNo