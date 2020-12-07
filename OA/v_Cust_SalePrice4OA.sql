
/*
销售价目表和销售折扣
*/
ALTER VIEW v_Cust_SalePrice4OA
AS
WITH DisCount AS
(
SELECT 
a.ID,a.Status,a.Code,a.Org
,b.Customer,b.ItemInfo_ItemID,b.ItemInfo_ItemCode
,b.DiscountMode,dbo.F_GetEnumName('UFIDA.U9.SPR.SaleDiscountPolicy.DiscountModeEnum',b.DiscountMode,'zh-cn')DiscountModeName
,b.CalculateMethod,dbo.F_GetEnumName('UFIDA.U9.SPR.SaleDiscountPolicy.CalculationMethodEnum',b.CalculateMethod,'zh-cn')CalculateMethodName
,b.CoefficientChoice,dbo.F_GetEnumName('UFIDA.U9.SPR.SaleDiscountPolicy.CoefficientChoiceEnum',b.CoefficientChoice,'zh-cn')CoefficientChoiceName
,b.ARTerm,b.PayTerm
,d.FromValue,d.ToValue,d.Discount
,a.PriceList,b.DocLineNo,d.LineNumber
FROM SPR_SaleDiscountPolicy a 
INNER JOIN SPR_SaleDiscountPolicyLine b ON a.Id=b.SaleDiscountPolicy
LEFT JOIN SPR_SaleDiscountSegment d ON b.ID=d.SaleDiscountPolicyLine
WHERE a.Cancel_Canceled=0 AND a.Effective_IsEffective=1 
AND a.Effective_EffectiveDate<=GETDATE() AND a.Effective_DisableDate>=GETDATE()
AND a.Status=2
)
SELECT * 
--,ROW_NUMBER()OVER(ORDER BY t.ID,t.ItemInfo_ItemCode,t.FromValue,t.Discount,t.Price)OrderNo
,t.ItemInfo_ItemCode+t.OrgCode+t.CurrencyCode+t.CustomerCode+t.SaleID+CONVERT(VARCHAR(10),t.DocLineNo)+CONVERT(VARCHAR(30),t.Price)+FORMAT(t.FromDate,'yyyyMMdd') OrderNo
FROM (
SELECT a.ID,a.Code,a.Org,o.Code OrgCode, o1.Name OrgName,a.Currency,cur.Code CurrencyCode,cur1.Name CurrencyName,a.IsIncludeTax
,ISNULL(b.Customer,'')Customer,ISNULL(cus.Code,'') CustomerCode,ISNULL(cus1.Name,'') CustomerName
,b.ItemInfo_ItemID,b.ItemInfo_ItemCode,b.ItemInfo_ItemName,m.SPECS
,isnull(c.Code,'') SaleID,ISNULL(c.LineNumber,0) DocLineNo
,CONVERT(DECIMAL(18,6),ISNULL(c.Discount,b.Price))Price
,b.Price OriginalPrice,c.Discount
--,c.DiscountMode,c.DiscountModeName,c.CalculateMethod,c.CalculateMethodName,c.CoefficientChoice,c.CoefficientChoiceName
,CONVERT(INT,c.FromValue)FromValue,CONVERT(INT,c.ToValue)ToValue
,b.FromDate,b.ToDate
FROM SPR_SalePriceList a 
INNER JOIN dbo.SPR_SalePriceLine b ON a.ID=b.SalePriceList
LEFT JOIN DisCount c ON a.id=c.PriceList AND b.ItemInfo_ItemID=c.ItemInfo_ItemID
LEFT JOIN dbo.Base_Currency cur ON a.Currency=cur.ID LEFT JOIN dbo.Base_Currency_Trl cur1 ON cur.ID=cur1.ID AND ISNULL(cur1.SysMLFlag,'zh-cn')='zh-cn'
LEFT JOIN dbo.CBO_Customer cus ON b.Customer=cus.ID LEFT JOIN dbo.CBO_Customer_Trl cus1 ON cus.ID=cus1.ID AND isnull(cus1.SysMLFlag,'zh-cn')='zh-cn'
LEFT JOIN dbo.Base_Organization o ON a.Org=o.ID LEFT JOIN dbo.Base_Organization_Trl o1 ON o.id=o1.ID AND ISNULL(o1.SysMLFlag,'zh-cn')='zh-cn'
LEFT JOIN dbo.CBO_ItemMaster m ON b.ItemInfo_ItemID=m.ID
WHERE a.Cancel_Canceled=0 AND a.Status=2 AND b.FromDate<=GETDATE() AND b.ToDate>=GETDATE() 
--AND o.Code<>'100'
AND b.Active=1
UNION ALL 
SELECT 1 ID,'11' code,a.Org,o.Code OrgCode,o1.Name OrgName,b.ID Currency,b.Code CurrencyCode,b1.Name CurrencyName,
1 IsIncludeTax,c.ID Customer,c.Code CustomerCode,c1.Name CustomerName
,a.ID ItemInfo_ItemID,a.Code ItemInfo_ItemCode,a.Name ItemInfo_ItemName,a.SPECS
,'0' SaleID,0 DocLineNo
,0 Price,0 OriginalPrice
,0 DisCount
--,''DiscountMode,''DiscountModeName,''CalculateMethod,''CalculateMethodName,''CoefficientChoice,''CoefficientChoiceName
,NULL FromValue,NULL ToValue,'2000-01-01' FromDate,'9999-12-31' ToDate
FROM dbo.CBO_ItemMaster a ,dbo.Base_Currency b,dbo.CBO_Customer c,dbo.Base_Currency_Trl b1
,dbo.Base_Organization o ,dbo.Base_Organization_Trl o1,dbo.CBO_Customer_Trl c1
WHERE a.Org=c.Org 
AND a.Effective_IsEffective=1 AND b.Effective_IsEffective=1 AND c.Effective_IsEffective=1
AND a.Org=o.ID AND o.ID=o1.ID AND ISNULL(o1.SysMLFlag,'zh-cn')='zh-cn'
AND b.ID=b1.ID AND ISNULL(b1.SysMLFlag,'zh-cn')='zh-cn'
AND c.ID=c1.ID AND ISNULL(c1.SysMLFlag,'zh-cn')='zh-cn'
AND a.ItemFormAttribute=10
AND b.Code IN ('C001','C009')
--AND o.Code<>'100'
) t




