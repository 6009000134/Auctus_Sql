/*
生产订单信息
*/
ALTER VIEW v_Cust_MO4Mes
as
SELECT  a.ID ,
        a.DocNo ,
        a.BusinessType ,
		a.ItemMaster,
        m.Code ,
        m.Name ,        
		v.LotParam ,
        l.Code LotCode ,
        l.Name LotName ,
        a.DocState ,
		a.StartDate,
		a.CompleteDate,
		a.CompleteWh,
		CONVERT(INT,a.ProductQty)ProductQty,
		ISNULL(CONVERT(INT,(SELECT SUM(t.CompleteQty) FROM dbo.MO_CompleteRpt t WHERE t.MO=a.ID)),0)TotalCompleteQty,
		ISNULL(CONVERT(INT,(SELECT SUM(CASE WHEN t.BusinessDirection=1 THEN t.StartQty*(-1) ELSE t.StartQty END)  FROM dbo.MO_MOStartInfo t WHERE t.MO=a.ID)),0)TotalStartQty,
        a.Cancel_Canceled Canceled,
		wh.ID WhID,
		wh.Code WhCode,
		wh1.Name WhName
FROM    dbo.MO_MO a
        INNER JOIN dbo.CBO_ItemMaster m ON a.ItemMaster = m.ID
        INNER JOIN dbo.CBO_InventoryInfo v ON a.ItemMaster = v.ItemMaster
        LEFT JOIN dbo.CBO_LotParameter l ON v.LotParam = l.ID
		LEFT JOIN dbo.CBO_Wh wh ON a.CompleteWh=wh.ID
		LEFT JOIN dbo.CBO_Wh_Trl wh1 ON wh.ID=wh1.ID AND ISNULL(wh1.SysMLFlag,'zh-cn')='zh-cn'