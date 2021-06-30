	/*
	�������洢�ص㣨�����ţ�
	*/
	ALTER  VIEW v_cust_ShipWh
	AS
		SELECT  
		CONVERT(VARCHAR(20),a.Wh)+CONVERT(VARCHAR(20),a.ItemID)+CONVERT(VARCHAR(200),a.LotID)UID,
		a.Wh WhID ,--�洢�ص�
				wh.Code WhCode ,--�洢�ص�
				wh1.Name WhName ,--�洢�ص�
				wh.Org ,--��֯
				a.ItemID ,--��Ʒ
				m.Code ,--��Ʒ
				m.Name ,--��Ʒ
				m.SPECS ,--��Ʒ
				a.TotalStoreQty ,--�����
				a.LotCode ,--����
				a.LotID--����
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

