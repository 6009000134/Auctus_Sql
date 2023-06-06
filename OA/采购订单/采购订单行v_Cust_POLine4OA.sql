ALTER VIEW v_Cust_POLine4OA
as
SELECT  a.ID ,
        a.DocNo ,
		b.ID LineID,
		b.DocLineNo,
		m.ID ItemID,
		m.Code ItemCode,
		m.Name ItemName,
		m.SPECS ,
		b.ReqQtyTU,
		b.SupplierConfirmQtyTU,
		b.FinallyPriceFC,
		b.Status,
        dbo.F_GetEnumName('UFIDA.U9.PM.PO.PODOCStatusEnum', a.Status, 'zh-cn') StatusName
FROM    dbo.PM_PurchaseOrder a INNER JOIN dbo.PM_POLine b ON a.ID=b.PurchaseOrder
INNER JOIN dbo.CBO_ItemMaster m ON b.ItemInfo_ItemID=m.ID
        

