
ALTER VIEW v_Cust_ECN4OA
AS
SELECT 
a.ID,
a.DocNo,a.DocLineNo
,CONVERT(INT,a.TotalCompleteQty)TotalCompleteQty
,CONVERT(INT,a.ProductQty)ProductQty
,CONVERT(INT,a.UnCompleteQty)UnCompleteQty,
a.SupplierName,a.Status
FROM 
(
SELECT a.ID,
a.DocNo,10 DocLineNo,a.TotalCompleteQty,a.ProductQty,a.ProductQty-a.TotalCompleteQty UnCompleteQty
,'' SupplierName
,dbo.F_GetEnumName('UFIDA.U9.MO.Enums.MOStateEnum',a.DocState,'zh-cn') Status
FROM dbo.MO_MO a
WHERE a.DocState!=3
UNION ALL
SELECT b.ID,a.DocNo,b.DocLineNo,b.SupplierConfirmQtyTU ProductQty
,b.TotalRecievedQtyTU TotalCompleteQty,b.SupplierConfirmQtyTU-b.TotalRecievedQtyTU UnCompleteQty
,sup1.Name SupplierName
,dbo.F_GetEnumName('UFIDA.U9.PM.PO.PODOCStatusEnum',b.Status,'zh-cn') Status
FROM dbo.PM_PurchaseOrder a INNER JOIN dbo.PM_POLine b ON a.ID=b.PurchaseOrder
LEFT JOIN dbo.CBO_Supplier sup ON a.Supplier_Supplier=sup.ID
LEFT JOIN dbo.CBO_Supplier_Trl sup1 ON sup.ID=sup1.ID AND sup1.SysMLFlag='zh-cn'
WHERE a.BizType IN (325,326)
AND b.Status NOT IN (3,4,5)
) a