/*
ɾ��Ԥ�ⶩ����
*/
ALTER PROC [dbo].[sp_Web_DeleteForecastLine]
(
@ID VARCHAR(50)
)
AS
BEGIN

DELETE FROM dbo.Auctus_ForecastLine WHERE ID=@ID

END 