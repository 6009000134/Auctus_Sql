--SELECT a.DocNo,a.DescFlexField_PrivateDescSeg1,a.DescFlexField_PrivateDescSeg5,a.DescFlexField_PrivateDescSeg4 
--FROM dbo.PM_PurchaseOrder a WHERE a.DocNo='PO30211202001'
--SELECT a.DocNo,a.DescFlexField_PrivateDescSeg1,a.DescFlexField_PrivateDescSeg5,a.DescFlexField_PrivateDescSeg4 
--FROM dbo.PM_PurchaseOrder a WHERE a.DocNo='PO30211130006'

----308818 PO30211202001
----308601 PO30211130006
--UPDATE PM_PurchaseOrder SET DescFlexField_PrivateDescSeg4='' WHERE DocNo='PO30211202001'
--UPDATE PM_PurchaseOrder SET DescFlexField_PrivateDescSeg4='' WHERE DocNo='PO30211130006'
----SELECT DescFlexField_PrivateDescSeg1 FROM dbo.PM_PODocType WHERE Code='PO30123'
--UPDATE PM_PODocType SET DescFlexField_PrivateDescSeg1='' WHERE Code='PO30123'
--UPDATE PM_PODocType SET DescFlexField_PrivateDescSeg1='1' WHERE Code='PO30123'

--UPDATE PM_PurchaseOrder SET DescFlexField_PrivateDescSeg4='308818' WHERE DocNo='PO30211202001'
--UPDATE PM_PurchaseOrder SET DescFlexField_PrivateDescSeg4='308601' WHERE DocNo='PO30211130006'