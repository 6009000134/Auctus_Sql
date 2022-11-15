USE [PLM]
GO

/****** Object:  View [dbo].[v_Auctus_ProjectMileStoneMail]    Script Date: 2022/10/27 14:39:05 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/*
PLM项目里程碑逾期邮件推送
需求：项目里程碑五大节点逾期未启动时，推送邮件给对应的销售员,佳美和moto固定推送给葛笑节和曾华扬
*/
;
ALTER VIEW [dbo].[v_Auctus_ProjectMileStoneMail]
AS

WITH CustomerData AS
(
SELECT b.PropertyValue,b.ObjectId,b.ObjectExtendID,a.CategoryId
FROM PS_ExtendSettings a INNER JOIN PJ_WorkExtend b ON a.SettingsId=b.SettingsId
WHERE a.ExtendName='客户'
),
SalerData AS
(
SELECT b.PropertyValue,b.ObjectId,b.ObjectExtendID,a.CategoryId
FROM PS_ExtendSettings a INNER JOIN PJ_WorkExtend b ON a.SettingsId=b.SettingsId
WHERE a.ExtendName='销售员'
),data1 AS
(
SELECT b.ParentWork,b.ChildWork
FROM dbo.PJ_WorkPiece a INNER JOIN dbo.PJ_WorkRelation b ON a.WorkId=b.ParentWork
WHERE ISNULL(a.ProjectId,'')='' --AND a.WorkId IN('4125055B-25D8-4207-948A-7A1B1076AA5C','8091BD42-B097-4548-92DB-CD3F8125E5C4')
),
Projects AS
(
SELECT DISTINCT b.ParentWork,'1'IsProject FROM dbo.PJ_WorkPiece a INNER JOIN dbo.PJ_WorkRelation b ON a.WorkId=b.ParentWork
WHERE ISNULL(a.ProjectId,'')='' 
),
data2 AS
(
SELECT a.*,ISNULL(b.IsProject,'0')IsProject
FROM data1 a LEFT JOIN Projects b ON a.ChildWork=b.ParentWork
),
data3 AS
(
SELECT a.ParentWork,a.ChildWork,a.RelationType,ISNULL(b.IsProject,'0')IsProject
FROM PJ_WorkRelation a LEFT JOIN Projects b ON a.ChildWork=b.ParentWork
),
pcs AS
(
SELECT a.ParentWork PID,a.ChildWork CID,a.IsProject FROM data2 a
UNION ALL
SELECT a.PID,b.ChildWork CID,b.IsProject IsProject 
FROM pcs a 
INNER JOIN data3 b ON a.CID=b.ParentWork AND b.RelationType IN (0,2) AND a.IsProject='0'
),
ProjectInfo AS
(
SELECT a.PID--,b.Principal,b.Priority,b.CategoryId,b.WorkCode ProjectCode,b.WorkName ProjectName
,c.WorkName
,c.PlanStartDate,c.ActualStartDate
--,a.Customer,a.Saler,a.state
FROM pcs a LEFT JOIN dbo.PJ_WorkPiece b ON a.PID=b.WorkId LEFT JOIN dbo.PJ_WorkPiece c ON a.CID=c.WorkId
WHERE 1=1
AND c.WorkName IN ('启动时间','Alpha日期','Beta日期','转量产日期','Seedstock日期','立项评审','转产评审','量产评审')
),
UnDos AS
(
SELECT DISTINCT a.PID FROM ProjectInfo a WHERE ISNULL(a.ActualStartDate,'')=''
AND CONVERT(DATE,a.PlanStartDate)<=CONVERT(DATE,GETDATE())
),
PivotData AS
(
SELECT a.PID--,a.Principal,a.ProjectCode,a.ProjectName,a.Priority,a.CategoryId,a.Customer,a.Saler,a.state
,CASE WHEN a.WorkName='启动时间' OR a.WorkName='立项评审' THEN a.PlanStartDate END '启动时间' 
,CASE WHEN a.WorkName='Alpha日期' THEN a.PlanStartDate END 'Alpha日期' 
,CASE WHEN a.WorkName='Beta日期' THEN a.PlanStartDate END 'Beta日期' 
,CASE WHEN a.WorkName='转量产日期' OR a.WorkName='转产评审' THEN a.PlanStartDate END '转量产日期' 
,CASE WHEN a.WorkName='Seedstock日期' OR a.WorkName='量产评审' THEN a.PlanStartDate END 'Seedstock日期' 
,CASE WHEN a.WorkName='启动时间' OR a.WorkName='立项评审' THEN a.ActualStartDate END '启动时间2' 
,CASE WHEN a.WorkName='Alpha日期' THEN a.ActualStartDate END 'Alpha日期2' 
,CASE WHEN a.WorkName='Beta日期' THEN a.ActualStartDate END 'Beta日期2' 
,CASE WHEN a.WorkName='转量产日期' OR a.WorkName='转产评审' THEN a.ActualStartDate END '转量产日期2' 
,CASE WHEN a.WorkName='Seedstock日期' OR a.WorkName='量产评审' THEN a.ActualStartDate END 'Seedstock日期2' 
FROM ProjectInfo a
),
WorkPieces AS
(
SELECT a.PID
,MIN(a.启动时间)启动时间,MIN(a.Alpha日期)Alpha日期,MIN(a.Beta日期)Beta日期,MIN(a.转量产日期)转量产日期,MIN(a.Seedstock日期)Seedstock日期 
,MIN(a.启动时间2)启动时间2,MIN(a.Alpha日期2)Alpha日期2,MIN(a.Beta日期2)Beta日期2,MIN(a.转量产日期2)转量产日期2,MIN(a.Seedstock日期2)Seedstock日期2
FROM PivotData a GROUP BY a.PID
)
SELECT a.PID,w.WorkCode ProjectCode,w.WorkName ProjectName
--,cus.PropertyValue Customer
,CASE WHEN PATINDEX('%佳美%',sd.PropertyValue)=0 AND PATINDEX('%moto%',sd.PropertyValue)=0  THEN  sd.PropertyValue ELSE '刘飞' END  Saler
,'力同股份asd' Customer
--,CASE WHEN PATINDEX('%佳美%',sd.PropertyValue)=0 AND PATINDEX('%moto%',sd.PropertyValue)=0  THEN  '刘飞' ELSE '刘飞' END  Saler
,CASE WHEN w.IsFreeze=1 THEN '冻结' WHEN  w.State=0 THEN '初始化' WHEN w.State=1 THEN '启动' WHEN w.State=2 THEN '完结' END State
,b.UserName Principal,c.CategoryName,sv.OptionName
,FORMAT(CONVERT(DATETIME,a.启动时间),'yyyy-MM-dd')启动时间
,FORMAT(CONVERT(DATETIME,a.Alpha日期),'yyyy-MM-dd')Alpha日期
,FORMAT(CONVERT(DATETIME,a.Beta日期),'yyyy-MM-dd')Beta日期
,FORMAT(CONVERT(DATETIME,a.转量产日期),'yyyy-MM-dd')转量产日期
,FORMAT(CONVERT(DATETIME,a.Seedstock日期),'yyyy-MM-dd')Seedstock日期
,CASE WHEN ISNULL(a.启动时间2,'')='' THEN NULL ELSE FORMAT(CONVERT(DATETIME,a.启动时间2),'yyyy-MM-dd')END 实际启动时间
,CASE WHEN ISNULL(a.Alpha日期2,'')='' THEN NULL ELSE FORMAT(CONVERT(DATETIME,a.Alpha日期2),'yyyy-MM-dd')END 实际Alpha日期
,CASE WHEN ISNULL(a.Beta日期2,'')='' THEN NULL ELSE FORMAT(CONVERT(DATETIME,a.Beta日期2),'yyyy-MM-dd')END 实际Beta日期
,CASE WHEN ISNULL(a.转量产日期2,'')='' THEN NULL ELSE FORMAT(CONVERT(DATETIME,a.转量产日期2),'yyyy-MM-dd')END 实际转量产日期
,CASE WHEN ISNULL(a.Seedstock日期2,'')='' THEN NULL ELSE FORMAT(CONVERT(DATETIME,a.Seedstock日期2),'yyyy-MM-dd')END 实际Seedstock日期
FROM WorkPieces a INNER JOIN UnDos u ON a.PID=u.PID INNER  JOIN dbo.PJ_WorkPiece w ON a.PID=w.WorkId LEFT JOIN dbo.SM_Users b ON w.Principal=b.UserId
LEFT JOIN dbo.PS_BusinessCategory c ON w.CategoryId=c.CategoryId
LEFT JOIN dbo.Sys_ValueOption sv ON SV.TypeName='13' AND w.Priority = CONVERT(INT,SV.OptionCode)  AND sv.LanguageId=0
LEFT JOIN CustomerData cus ON w.CategoryId=cus.CategoryId AND  w.WorkId=cus.ObjectId LEFT JOIN SalerData sd ON w.WorkId=sd.ObjectId AND w.CategoryId=sd.CategoryId
--WHERE w.IsFreeze=0 AND w.State=1





GO


