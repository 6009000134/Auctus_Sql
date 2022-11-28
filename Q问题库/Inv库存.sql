


SELECT a.ItemInfo_ItemCode,a.StoreQty,b.Code,wh1.Name FROM dbo.InvTrans_WhQoh a LEFT JOIN dbo.CBO_Wh b ON a.Wh=b.ID LEFT JOIN dbo.CBO_Wh_Trl wh1 ON b.ID=wh1.ID
LEFT JOIN dbo.CBO_WhStorageType c ON a.StorageType=c.StorageType AND a.Wh=c.Warehouse
WHERE b.Org=(SELECT id FROM dbo.Base_Organization WHERE code='300') AND b.LocationType=0--∆’Õ®≤÷
AND b.Effective_IsEffective=1
AND (c.IsCanMRP=1 or  b.code='231') 
and b.code<>'125'  
and b.code<>'126'
AND a.ItemInfo_ItemCode='301010128'
AND a.StoreQty>0

