/*
审核变更单
*/
ALTER PROC sp_ApproveMouldModify
(
@DocNo VARCHAR(50)
)
AS
BEGIN
	IF EXISTS(SELECT 1 FROM dbo.MouldModify WHERE DocNo=@DocNo AND Status=0)
	BEGIN
		--UPDATE dbo.Mould SET ModifyBy=a.CreateBy
		--FROM dbo.MouldModify
		DECLARE @ID INT,@MouldID int,@ModifyBy NVARCHAR(300)
        SELECT @ID=ID,@MouldID=MouldID,@ModifyBy=CreateBy FROM dbo.MouldModify WHERE DocNo=@DocNo		

		DECLARE @Sql NVARCHAR(MAX)
		SET @Sql='update Mould set ModifyBy='''+@ModifyBy+''',ModifyDate=GetDate(),'
		SET @Sql=@Sql+(SELECT a.ModifySeg+'='+'Convert('+CASE WHEN LOWER(a.DataType)='varchar' THEN 'varchar(100)' 
		WHEN LOWER(a.DataType)='decimal' OR LOWER(a.DataType)='numberic'  THEN 'decimal(18,4)' 
		ELSE a.datatype END +','''+a.DataAfterModify+'''),' 
		FROM dbo.MouldModifySeg a WHERE a.ModifyID=@ID
		FOR XML PATH(''))
		SET @Sql=LEFT(@Sql,LEN(@Sql)-1)
		SET @Sql=@Sql+' where ID='+CONVERT(NVARCHAR(10),@MouldID)
		EXEC sp_executesql @Sql		
		UPDATE dbo.MouldModify SET Status=1 WHERE DocNo=@DocNo		
		SELECT '1'MsgType,'审核成功!'Msg
		
	END
	ELSE IF EXISTS(SELECT 1 FROM dbo.MouldModify WHERE DocNo=@DocNo AND Status=1)
	BEGIN
		SELECT '0'MsgType,'订单已经审核，不可重复审核！'Msg
	END 
	ELSE
    BEGIN
		SELECT '0'MsgType,'审核失败！'Msg
	END 
END 