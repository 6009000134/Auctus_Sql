create VIEW Auctus_PurchaseOrderHkView
AS


SELECT a.ID,a.DocNo from  PM_purchaseorder a 
WHERE a.org=1001712010015192 AND PATINDEX('%PO%',a.DocNo)>0 --AND a.Supplier_Supplier=1001901240050460
AND a.Supplier_Supplier=1001901240050460




