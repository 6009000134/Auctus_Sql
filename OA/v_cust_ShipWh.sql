	/*
	出货单存储地点（带批号）
	*/
	ALTER  VIEW v_cust_ShipWh
	AS
		SELECT  
		CONVERT(VARCHAR(20),a.Wh)+CONVERT(VARCHAR(20),a.ItemID)+CONVERT(VARCHAR(200),a.LotID)UID,
		a.Wh WhID ,--存储地点
				wh.Code WhCode ,--存储地点
				wh1.Name WhName ,--存储地点
				wh.Org ,--组织
				a.ItemID ,--料品
				m.Code ,--料品
				m.Name ,--料品
				m.SPECS ,--料品
				a.TotalStoreQty ,--库存量
				a.LotCode ,--批号
				a.LotID--批号
		FROM    ( SELECT    a.ItemInfo_ItemID ItemID ,
							a.LotInfo_LotCode LotCode ,
							a.LotInfo_LotMaster_EntityID LotID ,
							a.Wh ,
							SUM(ISNULL(a.StoreQty,0)-ISNULL(A.[ResvStQty],0)-ISNULL(A.[ResvOccupyStQty],0)) TotalStoreQty
				  FROM      InvTrans_WhQoh a
				  WHERE     a.StoreQty > 0
				  GROUP BY  a.LotInfo_LotMaster_EntityID ,
							a.LotInfo_LotCode ,
							a.ItemInfo_ItemID ,
							a.Wh
				) a
				INNER JOIN dbo.CBO_Wh wh ON a.Wh = wh.ID
				INNER JOIN dbo.CBO_Wh_Trl wh1 ON wh.ID = wh1.ID
												 AND ISNULL(wh1.SysMLFlag, 'zh-cn') = 'zh-cn'
				INNER JOIN dbo.CBO_ItemMaster m ON a.ItemID = m.ID

