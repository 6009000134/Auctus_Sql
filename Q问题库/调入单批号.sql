SELECT a.DocNo,b.DocLineNo,b.LotInfo_LotCode ,i.LotParam,m.Code
FROM dbo.InvDoc_TransferIn a  INNER JOIN dbo.InvDoc_TransInLine b ON a.ID=b.TransferIn
INNER JOIN dbo.CBO_ItemMaster m ON b.ItemInfo_ItemID=m.ID
INNER JOIN dbo.CBO_InventoryInfo i ON m.ID=i.ItemMaster
WHERE a.DocNo='DB30220902003'
--AND m.code='310010005'
AND i.LotParam>0 AND b.LotInfo_LotCode=''