SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
GO
alter VIEW vw_tempWh
AS
        
		SELECT a.ItemInfo_ItemID ItemMaster,a.ItemInfo_ItemCode Code,SUM(a.StoreQty)StoreQty FROM dbo.InvTrans_WhQoh a INNER JOIN dbo.CBO_ItemMaster m ON a.ItemInfo_ItemID=m.ID
	INNER JOIN dbo.CBO_MrpInfo m1 ON m.ID=m1.ItemMaster AND m1.MRPPlanningType=0
	LEFT JOIN dbo.CBO_Wh b ON a.Wh=b.ID
	LEFT JOIN dbo.CBO_WhStorageType c ON a.StorageType=c.StorageType AND a.Wh=c.Warehouse
	WHERE b.Org=1001708020135665 AND b.LocationType=0--∆’Õ®≤÷
	AND b.Effective_IsEffective=1	--AND (c.IsCanMRP=1 or  b.code='231') 	--and b.code<>'125'  	--and b.code<>'126'
	GROUP By a.ItemInfo_ItemID,a.ItemInfo_ItemCode
	HAVING sum(a.StoreQty)>0

GO
