/*
失效字典项
*/
create   PROC sp_InvalidDictionary
(
@ID INT
)
AS
BEGIN
			DECLARE @WorkOrder VARCHAR(50)=''
			SELECT @WorkOrder=a.WorkOrder FROM dbo.mxqh_CompleteRpt a WHERE a.ID=@ID

			--检验删除后功完工数量是否小于U9中已经录入的完工数量
			

			DELETE FROM dbo.mxqh_CompleteRpt WHERE ID=@ID
			SELECT '1'MsgType,'删除成功！' Msg
END 

