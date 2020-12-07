CREATE PROC sp_DeleteRelations
(
@MouldID int
)
AS
BEGIN
	DELETE FROM dbo.Mould_ItemRelation WHERE MouldID=@MouldID
	SELECT '1'MsgType,'É¾³ý³É¹¦£¡'Msg
END 