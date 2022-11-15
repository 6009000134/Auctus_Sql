/*
"1、抓取8周收货-退货需求，当前时间往前推八周，按每周显示收货数据排序
2、抓取1中对应的发料数据，1、2中8周数据汇总后相减得出结存数量
3、结存数量大于0时，抓出下周需求  下下周需求：看MO和WPO 未发数量
MRP分类  buyer  mc sourcing"
*/
ALTER PROC [dbo].[sp_Auctus_RcvAndShipComp]
(
@Date DATE
)
as
set @Date=GETDATE()
DECLARE @nowWeek INT=0--当前为第几周
DECLARE @weeks INT=8--往前查几周
,@Org BIGINT=(SELECT id FROM dbo.Base_Organization WHERE code='300')
DECLARE @ED DATE=DATEADD(WEEK,@nowWeek,dbo.fun_GetMondayDate(@Date))
DECLARE @SD DATE=DATEADD(WEEK,@nowWeek-@weeks,dbo.fun_GetMondayDate(@Date))
DECLARE @wk INT=DATEPART(WEEK,dbo.fun_GetMondayDate(@Date))
DECLARE @firstSD DATE=@ED
DECLARE @firstED DATE=DATEADD(DAY,7,@ED)
DECLARE @secondSD DATE=@firstED
DECLARE @secondED DATE=DATEADD(DAY,7,@secondSD)
DECLARE @TaxRate DECIMAL(18,2)--税率
SET @TaxRate=1+dbo.fun_Auctus_GetTaxRate(@secondED)
--SELECT @SD,@ED,@wk,@secondSD,@secondED
IF OBJECT_ID('tempdb.dbo.#TempResult',N'U') is NOT null
BEGIN
DROP TABLE #TempResult
END 
IF OBJECT_ID('tempdb.dbo.#TempPick',N'U') is NULL
BEGIN
CREATE TABLE #TempPick
(	 
Itemmaster BIGINT,
ReqQty INT,
pickOfWk int
)
END
ELSE 
BEGIN
TRUNCATE TABLE #TempPick
END	
INSERT INTO #TempPick
SELECT b.ItemMaster,b.ActualReqQty-b.IssuedQty ReqQty
,CASE WHEN a.StartDate<@firstED THEN 1 ELSE 2 END pickOfWk
FROM dbo.MO_MO a INNER JOIN dbo.MO_MOPickList b ON a.ID=b.MO
WHERE a.docstate<>3 AND  a.Cancel_Canceled=0 AND a.IsHoldRelease=0 AND b.ActualReqQty-b.IssuedQty>0
AND b.ActualReqQty>0 AND b.IssueStyle!=4
AND a.Org=@Org
AND a.StartDate<@secondED
UNION 
SELECT d.ItemInfo_ItemID
,d.ActualReqQty-d.IssuedQty ReqQty
,CASE WHEN e.DeliveryDate<@firstED THEN 1 ELSE 2 END pickOfWk
FROM dbo.PM_PurchaseOrder a INNER JOIN dbo.PM_POLine b ON a.ID=b.PurchaseOrder 
LEFT JOIN dbo.CBO_SCMPickHead c ON b.SCMPickHead=c.ID LEFT JOIN dbo.CBO_SCMPickList d ON d.PicKHead=c.ID
LEFT JOIN dbo.PM_POShipLine e ON e.POLine=b.ID left join cbo_itemmaster f on d.iteminfo_itemid=f.id
Left JOIN CBO_ItemMaster m on b.ItemInfo_ItemID=m.ID
LEFT JOIN PM_PODocType dt ON a.DocumentType=dt.ID LEFT JOIN dbo.PM_PODocType_Trl dt1 ON dt.ID=dt1.ID AND ISNULL(dt1.SysMLFlag,'zh-cn')='zh-cn'
WHERE a.Status in(0,1,2) and b.Status in (0,1,2) AND a.Org=@Org AND e.DeliveryDate < @secondED
and  exists  (select 1 from PM_POShipLine b1  where e.ID=b1.ID   )
AND d.ActualReqQty-d.IssuedQty>0
and d.IssueStyle<>2
and a.Cancel_Canceled=0
AND c.ID IS NOT NULL

;
WITH RCV AS--收货/退货数据
(
SELECT a.ID,a.DocNo,b.DocLineNo,b.ItemInfo_ItemID,b.ConfirmDate,a.ReceivementType--0-采购收货 1-采购退货 2-销售退回收货
,b.ArriveQtyTU,b.RejectQtyTU,b.RcvQtyTU,b.RtnFillQtyTU,b.RtnDeductQtyTU
,dbo.fun_GetMondayDate(b.ConfirmDate)Mon
FROM dbo.PM_Receivement a INNER JOIN dbo.PM_RcvLine b ON a.ID=b.Receivement
WHERE 1=1 AND b.ConfirmDate>=@SD AND b.ConfirmDate<@ED
AND a.Org=@Org
--AND (b.RtnFillQtyTU>0 OR b.RtnDeductQtyTU>0)
--AND b.RejectQtyTU>0
),
Issues AS
(
SELECT a.BusinessCreatedOn,a.ID,a.DocNo,b.LineNum,b.Item,CASE WHEN a.IssueType=0 THEN b.IssuedQty WHEN a.IssueType=1 THEN (-1)*b.IssuedQty ELSE '' END IssuedQty,a.IssueType--0-发料 1-退料 2-挪料 3-超额
,dbo.fun_GetMondayDate(a.BusinessCreatedOn)Mon
FROM dbo.MO_IssueDoc a INNER JOIN dbo.MO_IssueDocLine b ON a.ID=b.IssueDoc
WHERE a.BusinessCreatedOn>=@SD AND a.BusinessCreatedOn<@ED
AND a.Org=@Org
UNION ALL
SELECT 
a.BusinessCreatedOn,a.ID,a.DocNo,b.LineNum,b.Item,CASE WHEN a.IssueDirection=0 THEN b.IssuedQty WHEN a.IssueDirection=1 THEN (-1)*b.IssuedQty ELSE '' END IssuedQty,a.IssueDirection--0 -领料 1-退料
,dbo.fun_GetMondayDate(a.BusinessCreatedOn)Mon
FROM dbo.PM_IssueDoc a INNER JOIN dbo.PM_IssueDocLine b ON a.ID=b.PMIssueDoc
WHERE a.BusinessCreatedOn>=@SD AND a.BusinessCreatedOn<@ED
AND a.Org=@Org
),
IssuesNow AS--当周发料
(
SELECT a.BusinessCreatedOn,a.ID,a.DocNo,b.LineNum,b.Item,CASE WHEN a.IssueType=0 THEN b.IssuedQty WHEN a.IssueType=1 THEN (-1)*b.IssuedQty ELSE '' END IssuedQty,a.IssueType--0-发料 1-退料 2-挪料 3-超额
,dbo.fun_GetMondayDate(a.BusinessCreatedOn)Mon
FROM dbo.MO_IssueDoc a INNER JOIN dbo.MO_IssueDocLine b ON a.ID=b.IssueDoc
WHERE a.BusinessCreatedOn>=@firstSD AND a.BusinessCreatedOn<@firstED
AND a.Org=@Org
UNION ALL
SELECT 
a.BusinessCreatedOn,a.ID,a.DocNo,b.LineNum,b.Item,CASE WHEN a.IssueDirection=0 THEN b.IssuedQty WHEN a.IssueDirection=1 THEN (-1)*b.IssuedQty ELSE '' END IssuedQty,a.IssueDirection--0 -领料 1-退料
,dbo.fun_GetMondayDate(a.BusinessCreatedOn)Mon
FROM dbo.PM_IssueDoc a INNER JOIN dbo.PM_IssueDocLine b ON a.ID=b.PMIssueDoc
WHERE a.BusinessCreatedOn>=@firstSD AND a.BusinessCreatedOn<@firstED
AND a.Org=@Org
),
TotalRCV AS
(
SELECT 
t.ItemInfo_ItemID,SUM(t.ArriveQtyTU-t.RejectQtyTU)TotalRcv,'W'+CONVERT(VARCHAR(20),@wk-DATEPART(WEEK,t.Mon))WK
FROM RCV t 
GROUP BY t.ItemInfo_ItemID,t.Mon
UNION ALL
SELECT 
t.ItemInfo_ItemID,SUM(t.ArriveQtyTU-t.RejectQtyTU)TotalRcv,'W'+CONVERT(VARCHAR(20),@wk-DATEPART(WEEK,dbo.fun_GetMondayDate(@Date)))WK
FROM RCV t
GROUP BY t.ItemInfo_ItemID
),
TotalShip AS
(
SELECT t.Item,SUM(t.IssuedQty)IssuedQty,'W'+CONVERT(VARCHAR(10),@wk-DATEPART(WEEK,t.Mon)) WK
FROM Issues t
GROUP BY t.Item,t.Mon
UNION ALL
SELECT t.Item,SUM(t.IssuedQty)IssuedQty,'W'+CONVERT(VARCHAR(10),@wk-DATEPART(WEEK,dbo.fun_GetMondayDate(@Date)))WK
FROM Issues t 
GROUP BY t.Item
)
SELECT ISNULL(a.ItemInfo_ItemID,b.Item)ItemMaster--mrp.Name,m.Code,m.Name,op1.Name Sourcing,op21.Name Buyer,op31.Name MC
,CONVERT(INT,ISNULL(a.W0,0)-ISNULL(b.W0,0)) '八周结存'
,CONVERT(INT,ISNULL(a.W0,0)) '总收',CONVERT(INT,ISNULL(b.W0,0)) '总发'
,CONVERT(INT,ISNULL(a.W8,0)) '第八周收',CONVERT(INT,ISNULL(b.W8,0)) '第八周发'
,CONVERT(INT,ISNULL(a.W7,0)) '第七周收',CONVERT(INT,ISNULL(b.W7,0)) '第七周发'
,CONVERT(INT,ISNULL(a.W6,0)) '第六周收',CONVERT(INT,ISNULL(b.W6,0)) '第六周发'
,CONVERT(INT,ISNULL(a.W5,0)) '第五周收',CONVERT(INT,ISNULL(b.W5,0)) '第五周发'
,CONVERT(INT,ISNULL(a.W4,0)) '第四周收',CONVERT(INT,ISNULL(b.W4,0)) '第四周发'
,CONVERT(INT,ISNULL(a.W3,0)) '第三周收',CONVERT(INT,ISNULL(b.W3,0)) '第三周发'
,CONVERT(INT,ISNULL(a.W2,0)) '第二周收',CONVERT(INT,ISNULL(b.W2,0)) '第二周发'
,CONVERT(INT,ISNULL(a.W1,0)) '第一周收',CONVERT(INT,ISNULL(b.W1,0)) '第一周发'
,
CONVERT(INT,(
SELECT SUM(t1.IssuedQty) FROM IssuesNow t1 WHERE t1.Item=ISNULL(a.ItemInfo_ItemID,b.Item) GROUP BY t1.Item
))IssuedNow
--,CASE WHEN a.W0-b.W0>0 THEN (SELECT SUM(t.ReqQty) FROM #TempPick t WHERE t.ItemMaster=ISNULL(a.ItemInfo_ItemID,b.Item) AND t.pickOfWk=1) ELSE 0 END Demand1
--,CASE WHEN a.W0-b.W0>0 THEN (SELECT SUM(t.ReqQty) FROM #TempPick t WHERE t.ItemMaster=ISNULL(a.ItemInfo_ItemID,b.Item))ELSE 0 END  Demand2
INTO #TempResult
FROM 
(SELECT 
*,'收'Type
FROM TotalRCV t
PIVOT (SUM(t.TotalRcv) FOR t.WK IN ([W0],[W1],[W2],[W3],[W4],[W5],[W6],[W7],[W8])) AS t1)a
FULL JOIN  
(SELECT * ,'发'Type
FROM TotalShip t
PIVOT (SUM(t.IssuedQty) FOR t.WK IN ([W0],[W1],[W2],[W3],[W4],[W5],[W6],[W7],[W8])) AS t1) b 
ON a.ItemInfo_ItemID=b.Item


;
WITH PPRData AS
(
SELECT * FROM (SELECT  b.ItemMaster,
						CASE WHEN a2.currency=1 AND  a2.IsIncludeTax = 1 
						THEN ISNULL(Price, 0)/@TaxRate
						WHEN a2.Currency=1 AND a2.IsIncludeTax=0
						THEN ISNULL(Price, 0)
						WHEN a2.Currency!=1 AND a2.IsIncludeTax=1
						THEN ISNULL(Price, 0) * dbo.fn_CustGetCurrentRate(a2.Currency, 1, GETDATE(), 2)/@TaxRate
						ELSE
                        ISNULL(Price, 0) * dbo.fn_CustGetCurrentRate(a2.Currency, 1, GETDATE(), 2) END Price,
						ROW_NUMBER()OVER(PARTITION BY a1.ItemInfo_ItemID ORDER BY a1.FromDate DESC) AS rowNum					--倒序排生效日
				FROM    PPR_PurPriceLine a1 right JOIN #TempResult b ON a1.ItemInfo_ItemID=b.ItemMaster
						INNER JOIN PPR_PurPriceList a2 ON a1.PurPriceList = a2.ID AND a2.Status = 2 AND a2.Cancel_Canceled = 0 AND a1.Active = 1
				WHERE   NOT EXISTS ( SELECT 1 FROM CBO_Supplier WHERE DescFlexField_PrivateDescSeg3 = 'OT01' AND a2.Supplier = ID ) AND 
						a2.Org = @Org
						AND a1.FromDate < @secondED)
						t WHERE t.rowNum=1
)
SELECT 
mrp.Name MRP分类,m.Code 料号,m.Name 品名,op1.Name Sourcing,op21.Name Buyer,op31.Name MC
,a.*
,CASE WHEN a.八周结存>0 THEN ISNULL((SELECT SUM(t.ReqQty) FROM #TempPick t WHERE t.ItemMaster=a.ItemMaster AND t.pickOfWk=1),0)+ISNULL(a.IssuedNow,0)  ELSE 0 END 未来一周需求
,CASE WHEN a.八周结存>0 THEN ISNULL((SELECT SUM(t.ReqQty) FROM #TempPick t WHERE t.ItemMaster=a.ItemMaster),0)+ISNULL(a.IssuedNow,0) ELSE 0 END 未来两周需求
,a.八周结存-CASE WHEN a.八周结存>0 THEN ISNULL((SELECT SUM(t.ReqQty) FROM #TempPick t WHERE t.ItemMaster=a.ItemMaster AND t.pickOfWk=1),0)-ISNULL(a.IssuedNow,0) ELSE 0 END 一周无需求
,a.八周结存-CASE WHEN a.八周结存>0 THEN ISNULL((SELECT SUM(t.ReqQty) FROM #TempPick t WHERE t.ItemMaster=a.ItemMaster ),0)-ISNULL(a.IssuedNow,0) ELSE 0 END  二周无需求
,p.Price 采购价,s.StandardPrice 结存价
,CONVERT(DECIMAL(18,2),ISNULL(p.Price,s.StandardPrice)*(a.八周结存-CASE WHEN a.八周结存>0 THEN ISNULL((SELECT SUM(t.ReqQty) FROM #TempPick t WHERE t.ItemMaster=a.ItemMaster AND t.pickOfWk=1),0)-ISNULL(a.IssuedNow,0) ELSE 0 END)) 一周无需求金额
,CONVERT(DECIMAL(18,2),ISNULL(p.Price,s.StandardPrice)*(a.八周结存-CASE WHEN a.八周结存>0 THEN ISNULL((SELECT SUM(t.ReqQty) FROM #TempPick t WHERE t.ItemMaster=a.ItemMaster ),0)-ISNULL(a.IssuedNow,0) ELSE 0 END)) 二周无需求金额
FROM #TempResult a
LEFT JOIN dbo.CBO_ItemMaster m ON a.ItemMaster=m.ID
LEFT JOIN dbo.vw_MRPCategory mrp ON m.DescFlexField_PrivateDescSeg22=mrp.Code
LEFT JOIN dbo.CBO_Operators op ON op.Code=m.DescFlexField_PrivateDescSeg6  LEFT JOIN dbo.CBO_Operators_Trl op1 ON op.id=op1.id AND op1.SysMLFlag='zh-cn'
LEFT JOIN dbo.CBO_Operators op2 ON op2.Code=m.DescFlexField_PrivateDescSeg23  LEFT JOIN dbo.CBO_Operators_Trl op21 ON op2.id=op21.id AND op21.SysMLFlag='zh-cn'
LEFT JOIN dbo.CBO_Operators op3 ON op3.Code=m.DescFlexField_PrivateDescSeg24  LEFT JOIN dbo.CBO_Operators_Trl op31 ON op3.id=op31.id AND op31.SysMLFlag='zh-cn'
LEFT JOIN PPRData p ON a.ItemMaster=p.ItemMaster
LEFT JOIN dbo.vw_ItemStandardPrice s ON s.LogTime=(SELECT MAX(LogTime) FROM dbo.vw_ItemStandardPrice) AND s.ItemId=a.ItemMaster
WHERE PATINDEX('4%',m.Code)=0 AND PATINDEX('5%',m.Code)=0 AND PATINDEX('6%',m.Code)=0 
ORDER BY  ISNULL(p.Price,s.StandardPrice)*(a.八周结存-CASE WHEN a.八周结存>0 THEN (SELECT SUM(t.ReqQty) FROM #TempPick t WHERE t.ItemMaster=a.ItemMaster )-ISNULL(a.IssuedNow,0)  ELSE 0 END) desc

--未来一周需求 未来两周需求  一周无需求 两周无需求 采购价 结存价
-- 4\5\6打头料号不需要


