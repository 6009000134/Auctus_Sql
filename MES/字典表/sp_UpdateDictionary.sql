/*
修改字典项
*/
ALTER  PROC sp_UpdateDictionary
(
@CreateBy VARCHAR(30)
)
AS
BEGIN
	IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#TempTable') AND TYPE='U')
	BEGIN
        BEGIN
			UPDATE dbo.mxqh_Base_Dic SET code=a.Code,name=a.Name,typecode=a.TypeCode,typeName=a.TypeName,IsActive=a.IsActive,ModifyBy=@CreateBy,ModifyDate=GETDATE()
			FROM #TempTable a WHERE a.id=dbo.mxqh_Base_Dic.ID
			SELECT '1'MsgType,'修改成功！' Msg
		END 		
	END 
	ELSE
    BEGIN
		SELECT '0'MsgType,'修改失败！' Msg
	END 
END 

