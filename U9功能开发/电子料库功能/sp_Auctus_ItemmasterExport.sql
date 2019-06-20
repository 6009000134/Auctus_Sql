/*
电子料导出功能
*/
ALTER PROC [dbo].[sp_Auctus_ItemmasterExport]
AS
BEGIN

SELECT a.DocLineNo,a.Code,a.Name,a.SPEC,a.OrderNo FROM dbo.Auctus_ItemMaster a
ORDER BY a.DocLineNo

END 


