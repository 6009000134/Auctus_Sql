/*
ʧЧ�ֵ���
*/
create   PROC sp_InvalidDictionary
(
@ID INT
)
AS
BEGIN
			DECLARE @WorkOrder VARCHAR(50)=''
			SELECT @WorkOrder=a.WorkOrder FROM dbo.mxqh_CompleteRpt a WHERE a.ID=@ID

			--����ɾ�����깤�����Ƿ�С��U9���Ѿ�¼����깤����
			

			DELETE FROM dbo.mxqh_CompleteRpt WHERE ID=@ID
			SELECT '1'MsgType,'ɾ���ɹ���' Msg
END 

