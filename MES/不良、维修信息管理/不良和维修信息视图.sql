/*
不良和维护信息视图
*/
alter VIEW vw_syQPoorTreeView
AS
SELECT a.ID,a.PID,a.Code,a.Name text,a.Layer,ISNULL(b.Name,a.Type) ParentType,a.type TopType,CONVERT(CHAR(1),a.IsMonitor)IsMonitor FROM dbo.syQPoor a  LEFT JOIN dbo.syQPoor b ON a.PID=b.ID



alter VIEW vw_syRPoorTreeView
AS
SELECT a.ID,a.PID,a.Code,a.Name text,a.Layer,ISNULL(b.Name,a.Type) ParentType,a.type TopType,CONVERT(CHAR(1),a.IsMonitor)IsMonitor FROM dbo.syRPoor a  LEFT JOIN dbo.syRPoor b ON a.PID=b.ID
