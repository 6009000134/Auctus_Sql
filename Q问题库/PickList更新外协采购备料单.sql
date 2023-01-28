SELECT  a.ID,a.DocNo,b.DocLineNo,c.SubLineNo,c.DeliveryDate,f.ActualReqDate,f.ID lid,c.DeficiencyQtyCU,DATEDIFF(HOUR,f.ActualReqDate,c.DeliveryDate)/24.00 Diff,mi.FixedLT
FROM dbo.PM_PurchaseOrder a INNER JOIN dbo.PM_POLine b ON a.ID=b.PurchaseOrder
INNER JOIN dbo.PM_POShipLine c ON b.ID=c.POLine
LEFT JOIN dbo.CBO_SCMPickHead d ON c.ID=d.PoShipLine
LEFT JOIN dbo.CBO_SCMPickList f ON d.ID=f.PicKHead
LEFT JOIN dbo.CBO_MrpInfo mi ON c.ItemInfo_ItemID=mi.ItemMaster
WHERE 1=1 AND b.Status IN (0,1,2) AND a.Cancel_Canceled=0 AND c.DeliveryDate!=(DATEADD(DAY,mi.FixedLT,f.ActualReqDate))
AND a.Org=(SELECT id FROM dbo.Base_Organization WHERE code='300') AND f.ActualReqQty-f.IssuedQty>0
AND c.DeficiencyQtyCU>0 AND a.DocNo LIKE 'WPO%'

--更新外协采购备料单

--UPDATE dbo.CBO_SCMPickList SET ActualReqDate=t.DeliveryDate-t.fixedlt FROM 
--(SELECT  a.ID,a.DocNo,b.DocLineNo,c.SubLineNo,c.DeliveryDate,f.ActualReqDate,mi.FixedLT,f.ID lid,c.DeficiencyQtyCU
--FROM dbo.PM_PurchaseOrder a INNER JOIN dbo.PM_POLine b ON a.ID=b.PurchaseOrder
--INNER JOIN dbo.PM_POShipLine c ON b.ID=c.POLine
--LEFT JOIN dbo.CBO_SCMPickHead d ON c.ID=d.PoShipLine
--LEFT JOIN dbo.CBO_SCMPickList f ON d.ID=f.PicKHead
--LEFT JOIN dbo.CBO_MrpInfo mi ON c.ItemInfo_ItemID=mi.ItemMaster
--WHERE 1=1 AND b.Status IN (0,1,2) AND a.Cancel_Canceled=0 AND c.DeliveryDate!=(DATEADD(DAY,mi.FixedLT,f.ActualReqDate))
--AND a.Org=(SELECT id FROM dbo.Base_Organization WHERE code='300') AND f.ActualReqQty-f.IssuedQty>0
--AND c.DeficiencyQtyCU>0 AND a.DocNo LIKE 'WPO%') t WHERE t.lid=dbo.CBO_SCMPickList.ID 

--204010517
/*
开立单据
MO-30220921005
AMO-30220421009
AMO-30221111002
*/
/*
AMO-30221107002   SO30202210020-10 
AMO-30221107001   SO30202210020-10
AMO-30221113001   SO30202208020-100
AMO-30221113002 SO30202208020-100
AMO-30221113003 SO30202208020-100
AMO-30220915001 NSO30220216001-50
AMO-30220404007 SO30202211016-10
AMO-30220916003 NSO30220913002-10
AMO-30220928002 NSO30220913002-10
AMO-30221111012 SO30202211016-10
*/
--非严格匹配
--201010652
--201010425
--201010651
--103010192
--已经改回严格匹配
--201010213


----103010192改成后焊
--SELECT a.ID,a.DemandCode,a.DocNo,m.Code,a.ProductQty,a.TotalCompleteQty FROM dbo.MO_MO a INNER JOIN dbo.CBO_ItemMaster m ON a.ItemMaster=m.ID
--WHERE m.Code IN ('201010652' ,'201010425','201010213','201010651','103010192','')
--AND a.Cancel_Canceled=0 AND a.CreatedOn<'2022-11-14' AND a.DemandCode!=-1 --AND a.DocNo NOT LIKE 'MO%'
--AND a.TotalCompleteQty!=a.ProductQty
--ORDER BY m.Code,a.DocNo


--UPDATE dbo.MO_MO SET DemandCode=-1 WHERE  DemandCode='38367' AND TotalCompleteQty!=ProductQty
--UPDATE dbo.MO_MO SET DemandCode=-1 WHERE DocNo NOT LIKE 'MO%' AND DemandCode='38373' AND TotalCompleteQty!=ProductQty
--UPDATE dbo.MO_MO SET DemandCode=-1 WHERE DocNo NOT LIKE 'MO%' AND DemandCode='35754' AND TotalCompleteQty!=ProductQty
--UPDATE dbo.MO_MO SET DemandCode=-1 WHERE DocNo NOT LIKE 'MO%' AND DemandCode='38066' AND TotalCompleteQty!=ProductQty
--UPDATE dbo.MO_MO SET DemandCode=-1 WHERE DocNo NOT LIKE 'MO%' AND DemandCode='36099' AND TotalCompleteQty!=ProductQty
--SELECT  a.ID,a.DemandCode,a.DocNo,m.Code
--fROM dbo.MO_MO a INNER JOIN dbo.CBO_ItemMaster m ON a.ItemMaster=m.ID
--WHERE a.DemandCode='35364' AND a.DocNo NOT LIKE 'MO%' AND TotalCompleteQty!=ProductQty
--UPDATE dbo.MO_MO SET DemandCode=-1 WHERE DocNo NOT LIKE 'MO%' AND DemandCode='35364' AND TotalCompleteQty!=ProductQty
--SELECT  a.ID,a.DemandCode,a.DocNo,m.Code
--fROM  
--dbo.MO_MO a INNER JOIN dbo.CBO_ItemMaster m ON a.ItemMaster=m.ID WHERE DocNo NOT LIKE 'MO%' AND DemandCode='35364' AND TotalCompleteQty!=ProductQty
--SELECT  a.ID,a.DemandCode,a.DocNo,m.Code
--fROM dbo.MO_MO a INNER JOIN dbo.CBO_ItemMaster m ON a.ItemMaster=m.ID
--WHERE a.DemandCode='37914'
--UPDATE dbo.MO_MO SET DemandCode=-1 WHERE DocNo='AMO-30220815033'
--38239 103010192 AMO-30221012004
--SELECT  a.ID,a.DemandCode,a.DocNo,m.Code
--fROM dbo.MO_MO a INNER JOIN dbo.CBO_ItemMaster m ON a.ItemMaster=m.ID
--WHERE a.DemandCode='38239'
--UPDATE dbo.MO_MO SET DemandCode=-1 WHERE DocNo='AMO-30221012004'
