/*
ɾ�����۶�����
*/
ALTER PROC sp_Web_DeleteSOLine
(
@ID INT
)
AS
BEGIN

DELETE FROM dbo.Auctus_SOLine WHERE ID=@ID

END