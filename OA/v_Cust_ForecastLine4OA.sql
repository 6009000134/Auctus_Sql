/*
Ô¤²â¶©µ¥ÐÐ
*/
ALTER  VIEW v_Cust_ForecastLine4OA
as
SELECT 
a.ID,a.DocNo
,b.ID LineID,b.DocLineNo,m.Code,m.Name,m.SPECS,CONVERT(INT,b.Num)Num,FORMAT(b.ShipPlanDate,'yyyy-MM-dd')ShipPlanDate,b.Customer_Customer,cus1.Name CustomerName
,CONVERT(INT,ISNULL((
SELECT 
SUM(t1.OrderByQtyTU)
FROM dbo.SM_SO t INNER JOIN dbo.SM_SOLine t1 ON t.ID=t1.SO
WHERE t1.SrcDoc=a.ID AND t1.SrcDocLine=b.ID
),0))UsedQty
FROM dbo.SM_ForecastOrder a INNER JOIN dbo.SM_ForecastOrderLine b ON a.ID=b.ForecastOrder
INNER JOIN dbo.SM_ForecastOrder_Trl a1 ON a.ID=a1.ID AND ISNULL(a1.SysMLFlag,'zh-cn')='zh-cn'
INNER JOIN dbo.CBO_ItemMaster m ON b.ItemInfo_ItemID=m.ID
LEFT JOIN dbo.CBO_Customer cus ON b.Customer_Customer=cus.ID LEFT JOIN dbo.CBO_Customer_Trl cus1 ON cus.ID=cus1.ID AND ISNULL(cus1.SysMLFlag,'zh-cn')='zh-cn'
WHERE a.Org=1001708020135665 AND b.Status=2


GO
