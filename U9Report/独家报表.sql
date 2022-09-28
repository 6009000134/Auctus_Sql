USE [AuctusERP]
GO
/****** Object:  StoredProcedure [dbo].[sp_Auctus_RcvRpt]    Script Date: 2022/8/24 11:03:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
时间：2022-08-23
需求人：采购部

1、抓取电子、包材、配件料品且外部供应商最新采购价大于3毛
2、料品的外部供应商中只有1家（独家）进行了供应商-料品交叉表承认的料号
3、根据查询时间，汇总料品所有外部供应商的收货数量及金额，以及该料号最新采购价格

*/
ALTER PROC [dbo].[sp_Auctus_RcvRpt]
(
@SD DATE,
@ED DATE
)
AS
--DECLARE @SD DATE='2021-08-23',@ED DATE='2022-08-23'
;
WITH ItemData AS
(
SELECT 
a.ID--,a.Code,a.Name
,MIN(s.Code)SupplierCode,MIN(s.ID)SupplierID,MIN(CASE WHEN s.Effective_IsEffective='1' THEN '1' ELSE '0' END )IsEffective
FROM dbo.CBO_ItemMaster a INNER JOIN dbo.CBO_SupplierItem b ON a.ID=b.ItemInfo_ItemID
INNER JOIN dbo.CBO_Supplier s ON b.SupplierInfo_Supplier=s.ID
WHERE b.DescFlexField_PrivateDescSeg1='True'--承认
AND s.DescFlexField_PrivateDescSeg3='WAI02'
AND a.DescFlexField_PrivateDescSeg22 IN ('MRP104','MRP105','MRP113')
AND a.Org=(SELECT id FROM dbo.Base_Organization WHERE code='300')
--AND a.Effective_IsEffective=1
GROUP BY a.ID--,a.Code,a.Name
HAVING COUNT(1)=1
),
FinalItem AS
(
SELECT * FROM (
SELECT 
c.*,a.Code PriceCode,b.Price,ROW_NUMBER()OVER(PARTITION BY c.ID ORDER BY b.FromDate DESC) RN,b.FromDate
FROM dbo.PPR_PurPriceList a 
INNER JOIN dbo.PPR_PurPriceLine b ON a.ID=b.PurPriceList
INNER JOIN ItemData c ON b.ItemInfo_ItemID=c.ID AND a.Supplier=c.SupplierID
WHERE a.Cancel_Canceled=0
AND b.Active=1
AND b.Price>0.3
) t WHERE t.RN=1
)
SELECT 
c.ID,MIN(m.Code)Code,MIN(m.Name)Name,MIN(m.SPECS)SPECS,MIN(CASE WHEN m.Effective_IsEffective=1 THEN '是' ELSE '否' END )IsActive,FORMAT(MIN(c.FromDate),'yyyy-MM-dd')FromDate,c.SupplierCode,s1.Name SupplierName,CONVERT(DECIMAL(18,6),MIN(c.Price))NewestPrice
,CONVERT(DECIMAL(18,2),SUM(CASE WHEN a.ReceivementType=0 THEN  b.RcvQtyTU*b.FinallyPriceTC*ACToFCExRate ELSE (-1)*b.RcvQtyTU*b.FinallyPriceTC*ACToFCExRate END))TotalMny
,CONVERT(INT,SUM(CASE WHEN a.ReceivementType=0 THEN  b.RcvQtyTU ELSE (-1)*b.RcvQtyTU END))TotalRcvQty
,MIN(ISNULL(mrp.Name,''))MRPType
FROM dbo.PM_Receivement a INNER JOIN dbo.PM_RcvLine b ON a.ID=b.Receivement
INNER JOIN FinalItem c ON b.ItemInfo_ItemID=c.ID
INNER JOIN dbo.CBO_Supplier s ON a.Supplier_Supplier=s.ID AND s.DescFlexField_PrivateDescSeg3='WAI02'
INNER JOIN dbo.CBO_Supplier_Trl s1 ON s.ID=s1.ID AND ISNULL(s1.SysMLFlag,'zh-cn')='zh-cn'
INNER JOIN dbo.CBO_ItemMaster m ON c.ID=m.ID
LEFT JOIN dbo.vw_MRPCategory mrp ON m.DescFlexField_PrivateDescSeg22=mrp.Code
WHERE a.BusinessDate>@SD AND a.BusinessDate<@ED
GROUP BY c.ID,c.SupplierCode,s1.Name
ORDER BY TotalMny DESC