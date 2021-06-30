/*
校验库存在手量大于杂发数量
*/
CREATE PROC sp_auctus_SV_CheckMiscShip
(
@DocNo VARCHAR(50),
@Result VARCHAR(MAX) OUT
)
as
IF EXISTS(
SELECT 1
FROM dbo.InvTrans_WhQoh a INNER JOIN dbo.CBO_Wh b ON a.Wh=b.ID
INNER JOIN dbo.CBO_WhStorageType c ON a.StorageType=c.StorageType AND a.Wh=c.Warehouse
INNER JOIN (
SELECT MIN(a.DocNo)DocNo,b.ItemInfo_ItemID,b.ItemInfo_ItemCode,b.Wh,SUM(b.StoreUOMQty)StoreUOMQty
,b.StoreType
FROM dbo.InvDoc_MiscShip a INNER JOIN dbo.InvDoc_MiscShipL b ON a.ID=b.MiscShip
WHERE 1=1
AND a.DocNo=@DocNo
GROUP BY b.ItemInfo_ItemID,b.Wh,b.StoreType,b.ItemInfo_ItemCode
) d ON c.StorageType=d.StoreType AND a.Wh=d.Wh AND a.ItemInfo_ItemID=d.ItemInfo_ItemID
WHERE a.StoreQty<d.StoreUOMQty )
BEGIN
	SET @Result=(SELECT 
	'料号：'+a.ItemInfo_ItemCode+'库存在手量'+CONVERT(VARCHAR(100),CONVERT(INT,a.StoreQty))+'小于杂发数量'+CONVERT(VARCHAR(100),CONVERT(INT,d.StoreUOMQty))+';'
	FROM dbo.InvTrans_WhQoh a INNER JOIN dbo.CBO_Wh b ON a.Wh=b.ID
	INNER JOIN dbo.CBO_WhStorageType c ON a.StorageType=c.StorageType AND a.Wh=c.Warehouse
	INNER JOIN (
	SELECT MIN(a.DocNo)DocNo,b.ItemInfo_ItemID,b.ItemInfo_ItemCode,b.Wh,SUM(b.StoreUOMQty)StoreUOMQty
	,b.StoreType
	FROM dbo.InvDoc_MiscShip a INNER JOIN dbo.InvDoc_MiscShipL b ON a.ID=b.MiscShip
	WHERE 1=1
	AND a.DocNo=@DocNo
	GROUP BY b.ItemInfo_ItemID,b.Wh,b.StoreType,b.ItemInfo_ItemCode
	) d ON c.StorageType=d.StoreType AND a.Wh=d.Wh AND a.ItemInfo_ItemID=d.ItemInfo_ItemID
	WHERE a.StoreQty<d.StoreUOMQty
	FOR XML PATH(''))
END 
ELSE
BEGIN
	SET @Result='1'
END 




