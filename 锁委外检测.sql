SELECT 
DISTINCT a.DocNo
--,d.PickLineNo
--,d.ItemInfo_ItemID Item,d.ItemInfo_ItemCode,d.ItemInfo_ItemName
--,d.IssuedQty--已发放数量  
--,d.ActualReqQty--实际需求数量	
,f1.Name
FROM dbo.PM_PurchaseOrder a INNER JOIN dbo.PM_POLine b ON a.ID=b.PurchaseOrder 
LEFT JOIN dbo.CBO_SCMPickHead c ON b.SCMPickHead=c.ID LEFT JOIN dbo.CBO_SCMPickList d ON d.PicKHead=c.ID
LEFT JOIN dbo.PM_POShipLine e ON e.POLine=b.ID
LEFT JOIN dbo.CBO_Supplier f ON a.Supplier_Supplier=f.ID LEFT JOIN dbo.CBO_Supplier_Trl f1 ON f.ID=f1.ID AND ISNULL(f1.SysMLFlag,'zh-cn')='zh-cn'
WHERE a.Status in(0,1,2) and b.Status in (0,1,2) AND a.Org=1001708020135665 --AND d.ActualReqDate BETWEEN @StartDate AND @EndDate
and  exists  (select 1 from PM_POShipLine b1  where e.ID=b1.ID   )
AND c.ID IS NOT NULL
AND d.IssueStyle<>2--2 是不发料
AND d.IssuedQty<d.ActualReqQty



;
WITH MOPickList AS
(
SELECT c.Code,c.Name,b.IssuedQty,b.ActualReqQty,b.IssueStyle  FROM dbo.MO_MO a INNER JOIN dbo.MO_MOPickList b ON a.ID=b.MO LEFT JOIN CBO_ItemMaster c ON b.ItemMaster=c.ID
WHERE a.DocNo='WMO-30180813032'
),
Woh AS
(
SELECT a.ItemInfo_ItemCode,SUM(a.StoreQty)StoreQty FROM dbo.InvTrans_WhQoh a LEFT JOIN dbo.CBO_Wh b ON a.Wh=b.ID
WHERE b.Org=1001708020135665 AND b.LocationType=0--普通仓
AND b.Effective_IsEffective=1
AND a.StorageType  not  in (5,1,2,0,3,7) --0、1、2、3、5、7 待检、在检、不合格、报废、冻结、待返工
AND a.ItemInfo_ItemCode IN 
(SELECT DISTINCT a.Code FROM MOPickList a)
--AND b.Code IN (SELECT strID FROM dbo.fun_Cust_StrToTable(@Wh))  
Group By a.ItemInfo_ItemCode 
)
SELECT * FROM MOPickList a LEFT JOIN Woh b ON a.Code=b.ItemInfo_ItemCode
WHERE (a.ActualReqQty-a.IssuedQty)>ISNULL(b.StoreQty,0)