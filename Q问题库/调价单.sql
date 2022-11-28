SELECT 
a.ID,a.DocNo,b.DocLineNo,b.ItemInfo_ItemID,b.ItemInfo_ItemCode,b.ItemInfo_ItemName
,a.CreatedOn,a.ModifiedOn,a.ApprovedOn
FROM dbo.PPR_PurPriceAdjustment a INNER JOIN dbo.PPR_PurPriceAdjustLine b ON a.ID=b.PurPriceAdjustment
WHERE DocNo='PA3022080062'

SELECT 
a.ID,a.Code,b.DocLineNo,b.ItemInfo_ItemCode,b.CreatedOn,b.ModifiedOn
FROM dbo.PPR_PurPriceList a inner JOIN dbo.PPR_PurPriceLine b ON a.ID=b.PurPriceList
WHERE a.Code='PPL2016030937' AND b.ItemInfo_ItemCode='306011029'



