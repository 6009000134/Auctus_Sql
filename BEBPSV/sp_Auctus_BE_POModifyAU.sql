/*
标题：采购订单变更单审核插件

*/
ALTER PROC [dbo].[sp_Auctus_BE_POModifyAU]
(
@DocNo VARCHAR(50),
@Result NVARCHAR(MAX) out
)
AS
BEGIN

--DECLARE @DocNo VARCHAR(50)
--DECLARE @Result NVARCHAR(max)
--SET @DocNo='POM30190114001'
DECLARE @Status INT

--更新重排建议状态
--BEGIN TRAN tran_U
DECLARE @tran_Error INT=0
DECLARE @RescheduleID BIGINT
BEGIN TRY--begin try
DECLARE cur CURSOR
FOR
SELECT b.DescFlexSegments_PrivateDescSeg1 FROM dbo.PM_POModify a INNER JOIN dbo.PM_POShiplineModify b ON a.ID=b.POModify
WHERE a.DocNo=@DocNo
OPEN cur
FETCH NEXT FROM cur INTO @RescheduleID
WHILE @@FETCH_STATUS=0
BEGIN--Start While
IF ISNULL(@RescheduleID,0)<>0
UPDATE dbo.MRP_Reschedule SET ConfirmType=1 WHERE ID=@RescheduleID
FETCH NEXT FROM cur INTO @RescheduleID
END --End While
CLOSE cur
DEALLOCATE cur--关闭游标
END TRY--End Try

BEGIN CATCH
SET @tran_Error=@tran_Error+ISNULL(@@ERROR,0)
END CATCH
IF @tran_Error>0
BEGIN
SET @Result='更新重排建议状态失败！'
--ROLLBACK TRAN
END
ELSE
BEGIN
SET @Result='1'
--COMMIT TRAN 
END 

END
