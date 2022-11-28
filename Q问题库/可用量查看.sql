--可用量查看
SELECT 
--* 
a.Doc_EntityType,a.CreatedOn,a.CreatedBy,a.ModifiedOn, a.ModifiedBy,a.DocNo,a.DocLineNo,a.DocSLNo,a.ItemInfo_ItemName,a.ItemInfo_ItemCode
,a.Wh,a.LotID,a.DemandQty,a.SupplyQty,a.StoreQtySU,a.SupplyMainQty,a.StoreQtyCU
FROM InvTrans_AvailableMatch a
WHERE a.ItemInfo_ItemCode='202010698'