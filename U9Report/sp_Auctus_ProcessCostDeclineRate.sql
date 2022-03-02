/*
需求人：成本中心-王庆
需求：
如沟通，800组织的马来加工费考核逻辑如下，请帮忙开发加工费下降率报表：
1.取供应商PROFESSIONAL TOOLS & DIES SDN BHD当期收货数量
2.马来加工费下降率：期初价格取价表9.0.002的最新有效价格，期末价格取收货单审核时间在9.0.003有效价格区间的价格，期初期末差价乘以当期收货数量，则为当期马来加工费下降金额。
*/

ALTER  PROC [dbo].[sp_Auctus_ProcessCostDeclineRate]
(
@Org BIGINT,
@StartDate DATETIME
,@EndDate DATETIME
,@Supplier BIGINT
,@StartTerm BIGINT
,@EndTerm BIGINT
)
as
--DECLARE 
--@Org BIGINT=(SELECT id FROM dbo.Base_Organization WHERE code='800'),
--@StartDate DATETIME='2019-12-21'
--,@EndDate DATETIME='2022-01-01'
--,@Supplier BIGINT=1001905130030112
--,@StartTerm BIGINT=1002201130067425
--,@EndTerm BIGINT=1002201130067570
BEGIN
	;
	WITH RcvData AS
    (
	SELECT 
	--a.DocNo,b.DocLineNo,b.ItemInfo_ItemID,b.ItemInfo_ItemCode,b.ItemInfo_ItemName
	b.ItemInfo_ItemID,b.ItemInfo_ItemCode
	,SUM(b.RcvQtyTU*(CASE WHEN a.ReceivementType=0 THEN 1 WHEN a.ReceivementType=1 THEN -1 END )) RcvQtyTU
	FROM dbo.PM_Receivement a INNER JOIN dbo.PM_RcvLine b ON a.ID=b.Receivement
	WHERE a.Org=@Org AND b.ConfirmDate>=@StartDate AND b.ConfirmDate<@EndDate
	AND PATINDEX('1%',b.ItemInfo_ItemCode)>0
	GROUP BY b.ItemInfo_ItemID,b.ItemInfo_ItemCode
	),
	StartPPRPrice AS
    (
	SELECT b.DocLineNo,CASE WHEN a.IsIncludeTax=0 THEN '否' ELSE '是'END IsIncludeTax,b.Price,b.ItemInfo_ItemCode,b.FromDate,b.Active,ROW_NUMBER()OVER(PARTITION BY b.ItemInfo_ItemCode ORDER BY b.FromDate DESC)RN
	FROM dbo.PPR_PurPriceList a INNER JOIN dbo.PPR_PurPriceLine b ON a.ID=b.PurPriceList AND b.Active=1 AND a.Status=2 AND a.Cancel_Canceled=0
	WHERE a.ID=@StartTerm
	),
	EndPPRPrice AS 
	(
	SELECT b.DocLineNo,CASE WHEN a.IsIncludeTax=0 THEN '否' ELSE '是'END IsIncludeTax,b.Price,b.ItemInfo_ItemCode,b.FromDate,b.Active,ROW_NUMBER()OVER(PARTITION BY b.ItemInfo_ItemCode ORDER BY b.FromDate DESC)RN	
	FROM dbo.PPR_PurPriceList a INNER JOIN dbo.PPR_PurPriceLine b ON a.ID=b.PurPriceList AND b.Active=1 AND a.Status=2 AND a.Cancel_Canceled=0
	WHERE a.ID=@EndTerm AND b.FromDate<=@EndDate
	)
	SELECT '委外加工费'ItemType,m.Code,m.Name,m.SPECS,p.Name ProductType,op1.Name Sourcing,CONVERT(INT,a.RcvQtyTU)RcvQtyTU,CONVERT(DECIMAL(18,4),b.Price) PriceStart,b.IsIncludeTax IsIncludeTaxStart,CONVERT(DECIMAL(18,2),b.Price*a.RcvQtyTU) TotalMoneyStart
	,CONVERT(DECIMAL(18,4),c.Price) PriceEnd,c.IsIncludeTax IsIncludeTaxEnd,CONVERT(DECIMAL(18,2),c.Price*a.RcvQtyTU) TotalMoneyEnd		,CASE WHEN ISNULL(c.Price,0)=0 THEN '无期末价格' when ISNULL(b.Price,0)=0 THEN '无期初价格' WHEN ISNULL((c.Price-b.Price),0)=0 THEN '0' ELSE FORMAT(c.Price-b.Price,'#.##') END  PriceDecline
	,CASE WHEN ISNULL(c.Price,0)=0 THEN '无期末价格' when ISNULL(b.Price,0)=0 THEN '无期初价格' WHEN ISNULL((c.Price-b.Price),0)=0 THEN '0' ELSE FORMAT((c.Price-b.Price)*a.RcvQtyTU,'#.##') END TotalMoneyDecline
	,CASE WHEN ISNULL(c.Price,0)=0 THEN '无期末价格' when ISNULL(b.Price,0)=0 THEN '无期初价格' WHEN ISNULL((c.Price-b.Price),0)=0 THEN '0' ELSE FORMAT((c.Price-b.Price)/b.Price*100,'#.##') END DeclineRate
	FROM RcvData a 
	INNER JOIN dbo.CBO_ItemMaster m ON a.ItemInfo_ItemID=m.ID 
	LEFT JOIN dbo.CBO_Operators op ON m.DescFlexField_PrivateDescSeg6=op.Code
	LEFT JOIN dbo.CBO_Operators_Trl op1 ON op.ID=op1.ID AND ISNULL(op1.SysMLFlag,'zh-cn')='zh-cn'	
	LEFT JOIN (SELECT Code,Name,GroupCode FROM dbo.v_Cust_KeyValue WHERE GroupCode='MatCategory')p ON m.DescFlexField_PrivateDescSeg9=p.Code
	LEFT JOIN StartPPRPrice b ON a.ItemInfo_ItemCode=b.ItemInfo_ItemCode 
	LEFT JOIN EndPPRPrice c ON a.ItemInfo_ItemCode=c.ItemInfo_ItemCode
	

END

