;
WITH POData AS
(
SELECT 
s1.Name ��Ӧ��,a.DocNo,b.DocLineNo,c.SubLineNo,dbo.F_GetEnumName('UFIDA.U9.PM.PO.PODOCStatusEnum',b.Status,'zh-cn')״̬,a.BusinessDate �ɹ�ҵ������,c.DeliveryDate �ɹ�����,c.SupplierConfirmQtyTU ȷ������
FROM dbo.PM_PurchaseOrder a INNER JOIN dbo.PM_POLine b ON a.ID=b.PurchaseOrder
INNER JOIN dbo.PM_POShipLine c ON b.ID=c.POLine
INNER JOIN dbo.CBO_Supplier s ON a.Supplier_Supplier=s.ID LEFT JOIN dbo.CBO_Supplier_Trl s1 ON s.ID=s1.ID AND s1.SysMLFlag='zh-cn'
WHERE s.Code IN ('2.GWSY.001','2.YXSJ.001','2.ANPT.001','2.JRSJ.002','2.XYMJ.001','2.LDXJ.001','2.ZSSS.001')
AND a.BusinessDate>DATEADD(YEAR,-1,GETDATE()) AND a.BusinessDate <GETDATE()
)
SELECT p.*,a.DocNo �ջ�����,a.BusinessDate �ջ���ҵ������,b.ConfirmDate �ջ�ȷ������,b.RcvQtyTU ʵ������
,m.Code,m.Name,m.SPECS
FROM dbo.PM_Receivement a INNER JOIN dbo.PM_RcvLine b ON a.ID=b.Receivement
INNER JOIN POData p ON b.SrcDoc_SrcDocNo=p.DocNo AND b.SrcDoc_SrcDocLineNo=p.DocLineNo AND b.SrcDoc_SrcDocSubLineNo=p.SubLineNo
INNER JOIN dbo.CBO_ItemMaster m ON b.ItemInfo_ItemID=m.ID AND m.DescFlexField_PrivateDescSeg22='MRP106'
ORDER BY p.��Ӧ��,p.DocNo,p.DocLineNo,p.SubLineNo,a.DocNo,b.DocLineNo
