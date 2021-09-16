ALTER VIEW v_Cust_PayReqSrcPO4OA
as
SELECT b.ID,
a.DocNo,a.Org,o.Code OrgCode,o1.name OrgName
,b.DocLineNo,sup.Code SupplierCode,sup1.Name SupplierName
,m.Code,m.Name,m.SPECS,a.TC,cur.Name CurrencyName,b.SupplierConfirmQtyTU,b.FinallyPriceTC,b.TotalMnyTC
FROM dbo.PM_PurchaseOrder a INNER JOIN dbo.PM_POLine b ON a.ID=b.PurchaseOrder
LEFT JOIN dbo.CBO_Supplier sup ON a.Supplier_Supplier=sup.ID LEFT JOIN dbo.CBO_Supplier_Trl sup1 ON sup.ID=sup1.ID AND ISNULL(sup1.SysMLFlag,'zh-cn')='zh-cn'
LEFT JOIN dbo.CBO_ItemMaster m ON b.ItemInfo_ItemID=m.ID
LEFT JOIN dbo.Base_Currency_Trl cur ON a.TC=cur.ID AND cur.SysMLFlag='zh-cn'
LEFT JOIN dbo.Base_Organization o ON a.org=o.ID
LEFT JOIN dbo.Base_Organization_Trl o1 ON o.ID=o1.ID AND o1.SysMLFlag='zh-cn'




GO
