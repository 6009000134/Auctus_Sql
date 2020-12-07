/*
不良和维修信息视图
*/
ALTER  VIEW vw_QPoorType
AS
SELECT DISTINCT Type text,-1 ID,Type TopType,(SELECT MIN(Layer) FROM dbo.syQPoor t WHERE t.Type=a.Type)Layer FROM dbo.syQPoor a

ALTER VIEW vw_RPoorType
AS
SELECT DISTINCT TYPE text,-1 ID,Type TopType,(SELECT MIN(Layer) FROM dbo.syRPoor t WHERE t.Type=a.Type)Layer FROM dbo.syRPoor a
