/*
�����豸
*/
alter PROC sp_AddEquipment
(
@CreateBy VARCHAR(30)
)
AS
BEGIN
	IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#TempTable') AND TYPE='U')
	BEGIN
		IF EXISTS(SELECT 1 FROM dbo.mxqh_Equipment a,#TempTable b WHERE a.Code=b.Code)
		BEGIN
			SELECT '0'MsgType,'�����ظ������ʧ�ܣ�'Msg
		END 		
		ELSE
        BEGIN
			INSERT INTO dbo.mxqh_Equipment
			        ( CreateBy ,
			          CreateDate ,
			          ModifyBy ,
			          ModifyDate ,
			          Code ,
			          Name ,
			          TypeID ,
			          TypeCode ,
			          TypeName ,
			          Type ,
			          CheckUOM ,
			          UpperLimit ,
			          LowerLimit ,
			          Remark
			        )
			SELECT    @CreateBy, -- CreateBy - nvarchar(50)
			          GETDATE() , -- CreateDate - datetime
			          @CreateBy , -- ModifyBy - nvarchar(50)
			          GETDATE() , -- ModifyDate - datetime
			          a.Code , -- Code - nvarchar(300)
			          a.Name, -- Name - nvarchar(300)
			          a.TypeID , -- TypeID - int
			          b.Code , -- TypeCode - nvarchar(300)
			          b.Name, -- TypeName - nvarchar(300)
			          a.Type, -- Type - nvarchar(300)
			          a.CheckUOM , -- CheckUOM - int
			          a.UpperLimit , -- UpperLimit - decimal(18, 4)
			          a.LowerLimit , -- LowerLimit - decimal(18, 4)
			          a.Remark  -- Remark - nvarchar(600)
			        FROM #TempTable a LEFT JOIN dbo.mxqh_Base_Dic b ON a.TypeID=b.ID
		SELECT '1'MsgType,'��ӳɹ���' Msg
		END 
	END 
	ELSE
    BEGIN
		SELECT '0'MsgType,'���ʧ�ܣ�' Msg
	END 
END 

