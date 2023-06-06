/*
厂商价目表行
*/
ALTER VIEW v_Cust_PurPriceLine4OA
as
SELECT * FROM (
SELECT 
b.ID--行ID  唯一值
,a.ID PriceListID--价表ID
,a.Code--价表编码
,o.ID OrgID,o.Code OrgCode,o1.Name OrgName--组织信息
,a.Supplier SupplierID,s.Code SupplierCode,s1.Name SupplierName--供应商信息
,a.SupplierSite--供应商位置
,a.Currency CurrencyID,cur.Code CurrencyCode,cur1.Name CurrencyName--币种
,a.IsIncludeTax--是否含税
,a.PricePerson--价格员
,a.Status--状态
,dbo.F_GetEnumName('UFIDA.U9.PPR.Enums.Status',a.Status,'zh-CN')StatusName--状态
,a.Cancel_Canceled--是否作废
,CASE WHEN a.Cancel_Canceled=1 THEN '作废' ELSE '' END Cancel_CanceledName--是否作废
,a.DescFlexField_PrivateDescSeg1--价表类型
,a1.Discription --备注
,b.DocLineNo--行号
,b.FromDate--生效日期
,b.ToDate--失效日期
,b.ItemInfo_ItemID
,m.Code ItemInfo_ItemCode
,m.Name ItemInfo_ItemName
,m.SPECS
,b.Price--价格
,CASE WHEN b.Active=1 THEN '√' ELSE '' END ActiveName--有效
,b.Active
,b.Manufacturer--厂牌
,b.Uom PurchaseUomID
,b.SrcDoc,b.SrcDocNo,b.SrcDoclineNo--来源单号
,ROW_NUMBER() OVER(PARTITION BY a.Supplier,b.ItemInfo_ItemID,b.Active,a.Cancel_Canceled,a.IsIncludeTax,a.Currency ORDER BY b.ToDate DESC)RN
FROM  dbo.PPR_PurPriceList a INNER JOIN dbo.PPR_PurPriceLine b ON a.ID=b.PurPriceList
INNER JOIN dbo.PPR_PurPriceList_Trl a1 ON a.ID=a1.ID AND a1.SysMLFlag='zh-cn'
INNER JOIN dbo.CBO_Supplier s ON a.Supplier=s.ID
INNER JOIN dbo.CBO_Supplier_Trl s1 ON s.ID=s1.ID AND s1.SysMLFlag='zh-cn'
INNER JOIN dbo.Base_Currency cur ON a.Currency=cur.ID
INNER JOIN dbo.Base_Currency_Trl cur1 ON cur.ID=cur1.ID AND cur1.SysMLFlag='zh-cn'
INNER JOIN dbo.Base_Organization o ON a.Org=o.ID
INNER JOIN dbo.Base_Organization_Trl o1 ON o.ID=o1.ID AND o1.SysMLFlag='zh-cn'
INNER JOIN dbo.CBO_ItemMaster m ON b.ItemInfo_ItemID=m.ID
WHERE 1=1
--AND a.Org=(SELECT id FROM dbo.Base_Organization WHERE code='300')
--AND b.ItemInfo_ItemCode='336030010'
--AND s.Code='2.CHXB.001'
) t 
WHERE t.Cancel_Canceled=0 AND t.Active=1 AND t.RN=1



