/*
��Ŀ���
*/
ALTER  PROC sp_auctus_ModifyProject
(
@ProjectID VARCHAR(200),
@WorkID varchar(200),
@StartDate datetime,
@EndDate datetime
)
AS
BEGIN	
	SET NOCOUNT ON
	DECLARE @error INT
	SET @error=0
	BEGIN TRY
		BEGIN TRAN
			INSERT INTO test1 VALUES('123')
			declare @info varchar(10)
			SET @info ='test'
			RAISERROR('��治��: ��Ʒ���:%s, ��ǰ���,�ֵǼ�������!', 16, 1, @info)
			INSERT INTO test1 VALUES('1232')
			SELECT '1' MsgType,'�޸ĳɹ�' Msg
		COMMIT TRAN
	END TRY
    BEGIN CATCH
			SELECT '0' MsgType,'���ݿ��쳣����:'+ERROR_MESSAGE() Msg
			ROLLBACK TRAN
	END CATCH

END 



