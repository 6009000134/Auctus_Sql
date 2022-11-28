;
WITH POData AS
(
SELECT 
s1.Name 供应商,a.DocNo,b.DocLineNo,c.SubLineNo,dbo.F_GetEnumName('UFIDA.U9.PM.PO.PODOCStatusEnum',b.Status,'zh-cn')状态,a.BusinessDate 采购业务日期,c.DeliveryDate 采购交期,c.SupplierConfirmQtyTU 确认数量
FROM dbo.PM_PurchaseOrder a INNER JOIN dbo.PM_POLine b ON a.ID=b.PurchaseOrder
INNER JOIN dbo.PM_POShipLine c ON b.ID=c.POLine
INNER JOIN dbo.CBO_Supplier s ON a.Supplier_Supplier=s.ID LEFT JOIN dbo.CBO_Supplier_Trl s1 ON s.ID=s1.ID AND s1.SysMLFlag='zh-cn'
WHERE s.Code IN ('2.GWSY.001','2.YXSJ.001','2.ANPT.001','2.JRSJ.002','2.XYMJ.001','2.LDXJ.001','2.ZSSS.001')
AND a.BusinessDate>DATEADD(YEAR,-1,GETDATE()) AND a.BusinessDate <GETDATE()
)
SELECT p.*,a.DocNo 收货单号,a.BusinessDate 收货单业务日期,b.ConfirmDate 收货确认日期,b.RcvQtyTU 实收数量
,m.Code,m.Name,m.SPECS
FROM dbo.PM_Receivement a INNER JOIN dbo.PM_RcvLine b ON a.ID=b.Receivement
INNER JOIN POData p ON b.SrcDoc_SrcDocNo=p.DocNo AND b.SrcDoc_SrcDocLineNo=p.DocLineNo AND b.SrcDoc_SrcDocSubLineNo=p.SubLineNo
INNER JOIN dbo.CBO_ItemMaster m ON b.ItemInfo_ItemID=m.ID AND m.DescFlexField_PrivateDescSeg22='MRP106'
ORDER BY p.供应商,p.DocNo,p.DocLineNo,p.SubLineNo,a.DocNo,b.DocLineNo
