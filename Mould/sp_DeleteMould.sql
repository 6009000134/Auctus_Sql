/*
删除模具料号，Deleted=1则表示已删除
*/
Alter PROC sp_DeleteMould
(
@ID INT
)
AS
BEGIN
	UPDATE dbo.Mould SET Deleted=1 WHERE ID=@ID
	UPDATE dbo.Mould_ItemRelation SET Deleted=1 WHERE MouldID=@ID--删除模具-料品关系
	SELECT '1'MsgType,'删除成功！'Msg
END 