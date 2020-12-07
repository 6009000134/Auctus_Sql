/*
缓存U9完工数据
*/
CREATE VIEW vw_MOCompleteQty
AS
SELECT a.DocNo,a.TotalCompleteQty FROM dbo.MO_MO a WHERE a.DocState IN (2,3)