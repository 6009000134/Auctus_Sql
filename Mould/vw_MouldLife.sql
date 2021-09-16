ALTER  VIEW vw_MouldLife
as

WITH data1 AS
(
SELECT 
a.Code,a.SupplierName,SUM(a.RcvQty)TotalRcvQty
FROM 
dbo.U9RcvData a 
GROUP BY a.Code,a.SupplierName
),
Relation AS
(
SELECT b.Code MouldCode,a.ItemCode,b.Holder,b.TotalNum,b.HoleNum,ISNULL(c.TotalRcvQty,0)TotalRcvQty
FROM  dbo.Mould_ItemRelation a INNER JOIN dbo.Mould b ON a.MouldID=b.ID
left JOIN data1 c ON b.Holder=c.SupplierName AND a.ItemCode=c.Code
),
Result AS
(
SELECT  
a.MouldCode,a.Holder,MIN(a.TotalNum)TotalNum,MIN(a.HoleNum)HoleNum,MIN(a.TotalNum*a.HoleNum) TotalNums,SUM(a.TotalRcvQty)TotalRcvQty
,(MIN(a.TotalNum*a.HoleNum)-SUM(a.TotalRcvQty)) RemainNums
,(SELECT b.ItemCode+',' FROM Relation b WHERE b.MouldCode=a.MouldCode FOR XML PATH(''))ItemCode
FROM Relation a
--WHERE a.MouldCode='504010001'
GROUP BY a.MouldCode,a.Holder
)
SELECT c.Code,c.Name,c.SPECS,a.*,a.RemainNums/CONVERT(DECIMAL(18,2),a.HoleNum) RemainNum
FROM Result a LEFT JOIN dbo.Mould c ON a.MouldCode=c.Code

