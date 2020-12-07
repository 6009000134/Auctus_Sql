/*
�޸��豸
*/
ALTER  PROC sp_UpdateEquipment
(
@CreateBy VARCHAR(30)
)
AS
BEGIN
	IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#TempTable') AND TYPE='U')
	BEGIN
        BEGIN
			IF EXISTS(SELECT 1 FROM dbo.mxqh_Equipment a,#TempTable b WHERE a.ID<>b.ID AND a.Code=b.Code)		
			BEGIN
				SELECT '0'MsgType,'�����ظ����޸�ʧ�ܣ�' Msg            
			END 
			ELSE
            BEGIN
				UPDATE dbo.mxqh_Equipment SET ModifyBy=@CreateBy,ModifyDate=GETDATE(),Code=a.Code,Name=a.Name,TypeID=a.TypeID,TypeCode=b.Code
				,TypeName=b.Name,Type=a.Type,CheckUOM=a.CheckUOM,UpperLimit=a.UpperLimit,LowerLimit=a.LowerLimit,Remark=a.Remark
				,IsActive=a.IsActive
				FROM #TempTable a LEFT JOIN dbo.mxqh_Base_Dic b ON a.TypeID=b.ID WHERE a.id=dbo.mxqh_Equipment.ID
				SELECT '1'MsgType,'�޸ĳɹ���' Msg
			END 
			
		END 		
	END 
	ELSE
    BEGIN
		SELECT '0'MsgType,'�޸�ʧ�ܣ�' Msg
	END 
END 

