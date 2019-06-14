/*
物料分类树状控件数据视图
*/
ALTER  VIEW MaterialTypeTreeView
AS
SELECT a.ID,a.TypeName text,a.TypeCode,a.LevelCode,a.PID,a.LastLayerFlag FROM dbo.baMaterialType a 

