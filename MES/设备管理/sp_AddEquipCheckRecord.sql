/*
�����豸����¼
*/
ALTER PROC sp_AddEquipCheckRecord
(
@CreateBy VARCHAR(30)
)
AS
BEGIN
	IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#TempTable') AND TYPE='U')
	BEGIN
		INSERT INTO dbo.mxqh_EquipCheck
		        ( CreateBy ,
		          CreateDate ,
		          ModifyBy ,
		          ModifyDate ,
		          CheckDate ,
		          Duration ,
		          WorkOrderID ,
		          EquipID ,
		          Record ,
		          Remark
		        )
		SELECT    @CreateBy, -- CreateBy - nvarchar(30)
		          GETDATE() , -- CreateDate - datetime
		          @CreateBy , -- ModifyBy - nvarchar(30)
		          GETDATE() , -- ModifyDate - datetime
		          a.CheckDate , -- CheckDate - datetime
		          a.Duration , -- Duration - int
		          a.WorkOrderID , -- WorkOrderID - int
		          a.EquipID , -- EquipID - int
		          a.Record , -- Record - decimal(18, 4)
		          a.Remark  -- Remark - nvarchar(300)
		        FROM #TempTable a
		SELECT '1'MsgType,'��ӳɹ���' Msg
	END 
	ELSE
    BEGIN
		SELECT '0'MsgType,'���ʧ�ܣ�' Msg
	END 
END 

