/*
从U9同步料品收货数据
*/
ALTER PROC sp_DailyGetRcvData
AS
BEGIN
	
	BEGIN TRAN tran_GetRcvData
	DECLARE @tran_error INT=0
	BEGIN TRY
		--同步料品数据
		DELETE FROM dbo.CBO_ItemMaster
		INSERT INTO CBO_ItemMaster
		SELECT a.ID,a.Code,a.Name,a.SPECS FROM U9.AuctusERP.dbo.CBO_ItemMaster a WHERE a.org=1001708020135665
		--同步收货数据
		DELETE FROM Mould_RCV
		INSERT INTO Mould_RCV
		SELECT a.DocNo,b.DocLineNo,a.Org,a.ApprovedOn,b.ItemInfo_ItemID,b.RcvQtyTU,b.ConfirmDate
		FROM U9.AuctusERP.dbo.PM_Receivement a INNER JOIN  U9.AuctusERP.dbo.PM_RcvLine b ON a.ID=b.Receivement
		INNER JOIN dbo.Mould_ItemRelation c ON b.ItemInfo_ItemID=c.ItemID
		WHERE a.Org=1001708020135665 AND c.Deleted=0 AND a.Status IN (4,5)
		AND a.ReceivementType=0--0\1 收货单\退货单
	END TRY
    BEGIN CATCH
		SET @tran_error=@tran_error+1
	END CATCH
	IF	@tran_error>0
	BEGIN
		ROLLBACK TRAN tran_GetRcvData
	END 
	ELSE
    BEGIN
		COMMIT TRAN tran_GetRcvData
	END 


END 
