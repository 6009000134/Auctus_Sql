
/*
项目里程碑
*/
alter VIEW V_Auctus_ProjectMilestone
as
WITH data1 AS
(
SELECT a.Principal,a.Priority,b.ParentWork,b.ChildWork 
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
SELECT a.PID,b.ChildWork CID,b.IsProject IsProject FROM pcs a 
INNER JOIN data3 b ON a.CID=b.ParentWork AND b.RelationType IN (0,2) AND a.IsProject='0'
),
ProjectInfo AS
(
SELECT b.WorkId PID,b.Principal,b.Priority,b.CategoryId,b.WorkCode ProjectCode,b.WorkName ProjectName
,c.WorkName
,c.PlanStartDate
FROM pcs a LEFT JOIN dbo.PJ_WorkPiece b ON a.PID=b.WorkId LEFT JOIN dbo.PJ_WorkPiece c ON a.CID=c.WorkId
WHERE 1=1
AND c.WorkName IN ('启动时间','Alpha日期','Beta日期','转量产日期','Seedstock日期','立项评审','转产评审','量产评审')
),
PivotData AS
(
SELECT a.PID,a.Principal,a.ProjectCode,a.ProjectName,a.Priority,a.CategoryId
,CASE WHEN a.WorkName='启动时间' OR a.WorkName='立项评审' THEN a.PlanStartDate END '启动时间' 
,CASE WHEN a.WorkName='Alpha日期' THEN a.PlanStartDate END 'Alpha日期' 
,CASE WHEN a.WorkName='Beta日期' THEN a.PlanStartDate END 'Beta日期' 
,CASE WHEN a.WorkName='转量产日期' OR a.WorkName='转产评审' THEN a.PlanStartDate END '转量产日期' 
,CASE WHEN a.WorkName='Seedstock日期' OR a.WorkName='量产评审' THEN a.PlanStartDate END 'Seedstock日期' 
FROM ProjectInfo a
),
WorkPieces AS
(
SELECT a.PID,a.Principal,a.ProjectCode,a.ProjectName,a.Priority,a.CategoryId
,MIN(a.启动时间)启动时间,MIN(a.Alpha日期)Alpha日期,MIN(a.Beta日期)Beta日期,MIN(a.转量产日期)转量产日期,MIN(a.Seedstock日期)Seedstock日期 
FROM PivotData a GROUP BY a.PID,a.Principal,a.ProjectCode,a.ProjectName,a.Priority,a.CategoryId
)
SELECT a.PID,a.ProjectCode,a.ProjectName
,b.UserName Principal,c.CategoryName,sv.OptionName
,FORMAT(CONVERT(DATETIME,a.启动时间),'yyyy-MM-dd')启动时间
,FORMAT(CONVERT(DATETIME,a.Alpha日期),'yyyy-MM-dd')Alpha日期
,FORMAT(CONVERT(DATETIME,a.Beta日期),'yyyy-MM-dd')Beta日期
,FORMAT(CONVERT(DATETIME,a.转量产日期),'yyyy-MM-dd')转量产日期
,FORMAT(CONVERT(DATETIME,a.Seedstock日期),'yyyy-MM-dd')Seedstock日期
FROM WorkPieces a LEFT JOIN dbo.SM_Users b ON a.Principal=b.UserId
LEFT JOIN dbo.PS_BusinessCategory c ON a.CategoryId=c.CategoryId
LEFT JOIN dbo.Sys_ValueOption sv ON SV.TypeName='13' AND a.Priority = CONVERT(int,SV.OptionCode)  AND sv.LanguageId=0






GO
