/*
ɾ��ģ���Ϻţ�Deleted=1���ʾ��ɾ��
*/
Alter PROC sp_DeleteMould
(
@ID INT
)
AS
BEGIN
	UPDATE dbo.Mould SET Deleted=1 WHERE ID=@ID
	UPDATE dbo.Mould_ItemRelation SET Deleted=1 WHERE MouldID=@ID--ɾ��ģ��-��Ʒ��ϵ
	SELECT '1'MsgType,'ɾ���ɹ���'Msg
END 