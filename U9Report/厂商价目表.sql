SELECT *
FROM (
 SELECT a21.Name 组织,a1.Name 价表名称,b.ItemInfo_ItemCode 料号,b.ItemInfo_ItemName 名称
 ,CASE WHEN a.IsIncludeTax=1 THEN '是' ELSE '否'END 是否含税
 ,m1.Name 币种
 ,dbo.fn_CustGetCurrentRate(a.Currency,1,GETDATE(),2)汇率
 ,b.Price 价格 
 ,CASE WHEN a.IsIncludeTax=1 THEN b.Price*dbo.fn_CustGetCurrentRate(a.Currency,1,GETDATE(),2)/1.13
 ELSE  b.Price*dbo.fn_CustGetCurrentRate(a.Currency,1,GETDATE(),2) END 未税人命币价格
 ,b.FromDate 生效时间,b.ToDate 失效时间 ,a2.ModifiedOn 最新修改时间
 ,ROW_NUMBER()OVER(PARTITION BY a.Org,b.ItemInfo_ItemID ORDER BY b.ItemInfo_ItemCode,b.FromDate desc)RN
 FROM dbo.PPR_PurPriceList a 
 LEFT JOIN dbo.PPR_PurPriceList_Trl a1 ON a.ID=a1.ID left JOIN dbo.Base_Organization a2 ON a.Org=a2.ID  LEFT JOIN dbo.Base_Organization_Trl a21 ON a2.ID=a21.ID
 INNER JOIN dbo.PPR_PurPriceLine b ON a.ID=b.PurPriceList
 LEFT JOIN dbo.Base_Currency m ON a.Currency=m.ID LEFT JOIN dbo.Base_Currency_Trl m1 ON m.ID=m1.ID AND m1.SysMLFlag='zh-cn'
 WHERE PATINDEX('S40%',b.ItemInfo_ItemCode)>0
 AND b.Active=1
 AND b.FromDate<GETDATE()
 AND b.ToDate>GETDATE()
)t WHERE t.RN=1
 --ORDER BY a2.Code

