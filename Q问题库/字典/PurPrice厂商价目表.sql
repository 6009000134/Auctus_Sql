--厂商价目表
SELECT 
a.ID,a.Code
,a.Supplier SupplierID,s.Code SupplierCode,s1.Name SupplierName--供应商信息
,a.SupplierSite--供应商位置
,a.Currency CurrencyID,cur.Code CurrencyCode,cur1.Name CurrencyName--币种
,a.IsIncludeTax--是否含税
,a.PricePerson--价格员
,a.Status--状态
,dbo.F_GetEnumName('UFIDA.U9.PPR.Enums.Status',a.Status,'zh-CN')StatusName--状态
,a.Cancel_Canceled--是否作废
,CASE WHEN a.Cancel_Canceled=1 THEN '作废' ELSE '' END 作废--是否作废
,a.DescFlexField_PrivateDescSeg1--价表类型
,a1.Discription --备注
,b.ID LineID--行ID
,b.DocLineNo--行号
,b.FromDate--生效日期
,b.ToDate--失效日期
,b.ItemInfo_ItemCode
,b.Price--价格
,CASE WHEN b.Active=1 THEN '√' ELSE '' END 是否生效--有效
,b.Active
,b.Manufacturer--厂牌
,b.SrcDoc,b.SrcDocNo,b.SrcDoclineNo--来源单号
FROM  dbo.PPR_PurPriceList a INNER JOIN dbo.PPR_PurPriceLine b ON a.ID=b.PurPriceList
INNER JOIN dbo.PPR_PurPriceList_Trl a1 ON a.ID=a1.ID AND a1.SysMLFlag='zh-cn'
INNER JOIN dbo.CBO_Supplier s ON a.Supplier=s.ID
INNER JOIN dbo.CBO_Supplier_Trl s1 ON s.ID=s1.ID AND s1.SysMLFlag='zh-cn'
INNER JOIN dbo.Base_Currency cur ON a.Currency=cur.ID
INNER JOIN dbo.Base_Currency_Trl cur1 ON cur.ID=cur1.ID AND cur1.SysMLFlag='zh-cn'
WHERE a.Org=(SELECT id FROM dbo.Base_Organization WHERE code='300')
AND b.ItemInfo_ItemCode='336030010'
AND s.Code='2.CHXB.001'


--价表排序
SELECT t.*,s.OrderNO ,CASE WHEN t.未税价格排序=ISNULL(s.OrderNO,0) THEN '是' ELSE '否' END 是否一致
FROM (SELECT t.Name 组织 ,t.ItemInfo_ItemCode 料号,t.CreatedOn 创建时间,t.ModifiedOn 修改时间,t.FromDate 生效日期,t.ToDate 失效日期,t.SupplierName 供应商名称 ,
CASE WHEN t.IsIncludeTax =1 THEN '是' ELSE '否' END 是否含税
,t.CurName 币种,t.Price 价格 ,t.NetPrice 未税价_人民币
,ROW_NUMBER()OVER(PARTITION BY t.name,t.ItemInfo_ItemCode ORDER BY t.NetPrice)未税价格排序 
,t.Supplier,t.ItemInfo_ItemID
FROM 
(
SELECT 
o1.Name,a.Supplier,s1.Name SupplierName,a.IsIncludeTax,b.ItemInfo_ItemID,b.ItemInfo_ItemCode,b.Price,b.CreatedOn,b.ModifiedOn
,a.Currency,cur.Name CurName
,b.FromDate,b.ToDate
,CASE WHEN a.currency=1 AND  a.IsIncludeTax = 1 
 THEN ISNULL(Price, 0)/1.13
 WHEN a.Currency=1 AND a.IsIncludeTax=0
 THEN ISNULL(Price, 0)
 WHEN a.Currency!=1 AND a.IsIncludeTax=1
 THEN ISNULL(Price, 0) * dbo.fn_CustGetCurrentRate(a.Currency, 1, GETDATE(), 2)/1.13
 ELSE
 ISNULL(Price, 0) * dbo.fn_CustGetCurrentRate(a.Currency, 1, GETDATE(), 2) END NetPrice
,ROW_NUMBER() OVER(PARTITION BY a.Org,a.Supplier,b.ItemInfo_ItemID ORDER BY b.FromDate) RN
FROM dbo.PPR_PurPriceList a INNER JOIN dbo.PPR_PurPriceLine b ON a.ID=b.PurPriceList
LEFT JOIN dbo.CBO_Supplier s ON a.Supplier=s.ID 
LEFT JOIN dbo.CBO_Supplier_Trl s1 ON a.Supplier=s1.ID AND s1.SysMLFlag='zh-cn'
LEFT JOIN dbo.Base_Organization_Trl o1 ON a.Org=o1.ID AND o1.SysMLFlag='zh-cn'
LEFT JOIN dbo.Base_Currency_Trl cur ON a.Currency=cur.ID AND cur.SysMLFlag='zh-cn'
WHERE b.Active=1 AND GETDATE()BETWEEN b.FromDate AND b.ToDate AND a.Cancel_Canceled=0
AND a.Org=(SELECT id FROM dbo.Base_Organization WHERE code='300')
AND s.DescFlexField_PrivateDescSeg3 NOT IN ('NEI01','OT01')
)t  
WHERE t.RN=1
)t
LEFT JOIN dbo.CBO_SupplySource s ON t.Supplier=s.SupplierInfo_Supplier AND t.ItemInfo_ItemID=s.ItemInfo_ItemID
ORDER BY t.组织,t.料号
--ORDER BY a.Org,b.ItemInfo_ItemID
