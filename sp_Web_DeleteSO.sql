/*
ɾ�����۶����Լ�������
*/
CREATE PROC sp_Web_DeleteSO
(
@ID INT
)
AS
BEGIN

DELETE FROM dbo.Auctus_SOLine WHERE SO=@ID

DELETE FROM dbo.Auctus_SO WHERE ID=@ID

END
