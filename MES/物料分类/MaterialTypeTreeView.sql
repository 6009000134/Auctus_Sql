/*
���Ϸ�����״�ؼ�������ͼ
*/
ALTER  VIEW MaterialTypeTreeView
AS
SELECT a.ID,a.TypeName text,a.TypeCode,a.LevelCode,a.PID,a.LastLayerFlag FROM dbo.baMaterialType a 

