/*
�޸��豸������ϵ
*/
ALTER   PROC sp_UpdateEquipMoRelate
(
@CreateBy VARCHAR(30)
)
AS
BEGIN
	IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#TempTable') AND TYPE='U')
	BEGIN
        BEGIN
			IF EXISTS(SELECT 1 FROM dbo.mxqh_EquipMoRelation a,#TempTable b WHERE a.ID<>b.ID AND a.EquipID=b.EquipID AND a.WorkOrderID=b.WorkOrderID)		
			BEGIN
				SELECT '0'MsgType,'�ü�¼�Ѵ��ڣ��޸�ʧ�ܣ�' Msg            
			END 
			ELSE
            BEGIN			
				UPDATE dbo.mxqh_EquipMoRelation SET EquipID=a.EquipID,WorkOrderID=a.WorkOrderID,LowerLimit=a.LowerLimit,UpperLimit=a.UpperLimit
				,Remark=a.Remark,ModifyBy=@CreateBy,ModifyDate=GETDATE()
				FROM #TempTable a WHERE a.ID=dbo.mxqh_EquipMoRelation.ID
				SELECT '1'MsgType,'�޸ĳɹ���' Msg
			END 
			
		END 		
	END 
	ELSE
    BEGIN
		SELECT '0'MsgType,'�޸�ʧ�ܣ�' Msg
	END 
END 

