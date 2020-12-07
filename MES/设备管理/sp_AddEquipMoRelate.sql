/*
�����豸������ϵ
*/
ALTER PROC sp_AddEquipMoRelate
(
@CreateBy VARCHAR(30)
)
AS
BEGIN
	IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#TempTable') AND TYPE='U')
	BEGIN
		IF EXISTS(SELECT 1 FROM dbo.mxqh_EquipMoRelation a,#TempTable b WHERE a.WorkOrderID=b.WorkOrderID AND a.EquipID=b.EquipID)
		BEGIN
			SELECT '0'MsgType,'��¼�Ѵ��ڣ����ʧ�ܣ�'Msg
		END 		
		ELSE
        BEGIN
			INSERT INTO dbo.mxqh_EquipMoRelation
			        ( CreateBy ,
			          CreateDate ,
			          ModifyBy ,
			          ModifyDate ,
			          WorkOrderID ,
			          EquipID ,
			          LowerLimit ,
			          UpperLimit ,
			          Remark
			        )
			SELECT @CreateBy , -- CreateBy - nvarchar(50)
			          GETDATE() , -- CreateDate - datetime
			          @CreateBy, -- ModifyBy - nvarchar(50)
			          GETDATE() , -- ModifyDate - datetime
			          a.WorkOrderID , -- WorkOrderID - int
			          a.EquipID , -- EquipID - int
			          a.LowerLimit , -- LowerLimit - decimal(18, 4)
			          a.UpperLimit , -- UpperLimit - decimal(18, 4)
			          a.Remark  -- Remark - nvarchar(300)
			        FROM #TempTable a
		SELECT '1'MsgType,'��ӳɹ���' Msg
		END 
	END 
	ELSE
    BEGIN
		SELECT '0'MsgType,'���ʧ�ܣ�' Msg
	END 
END 

