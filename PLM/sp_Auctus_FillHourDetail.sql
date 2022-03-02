/*
工时报备明细，取人员、部门、项目、任务
*/
ALTER PROC [dbo].[sp_Auctus_FillHourDetail]
(
@UserName VARCHAR(50),
@ProjectCode VARCHAR(50),
@ProjectName VARCHAR(50),
@SD DATE,
@ED DATE
)
AS
BEGIN
	--DECLARE @SD DATE='2021-01-01',@ED DATE='2021-10-10'
	;
	WITH ExtendData AS
	(
	SELECT b.PropertyValue,b.ObjectId,b.ObjectExtendID
	FROM PS_ExtendSettings a INNER JOIN PJ_WorkExtend b ON a.SettingsId=b.SettingsId
	WHERE a.ExtendName='项目大类'
	),
	ExtendData1 AS
	(
	SELECT b.PropertyValue,b.ObjectId,b.ObjectExtendID
	FROM PS_ExtendSettings a INNER JOIN PJ_WorkExtend b ON a.SettingsId=b.SettingsId
	WHERE a.ExtendName='项目分类'
	),
	ExtendData2 AS
	(
	SELECT b.PropertyValue,b.ObjectId,b.ObjectExtendID
	FROM PS_ExtendSettings a INNER JOIN PJ_WorkExtend b ON a.SettingsId=b.SettingsId
	WHERE a.ExtendName='关联项目编码'
	),
	data1 AS
	(
	SELECT 
	c.DepartmentName,p.WorkId ProjectID,p.WorkCode,p.WorkName,b.UserName,a.FillHour
	,d.PropertyValue ProjectType,d1.PropertyValue ProjectCategory,d2.PropertyValue ProjectRelated,w.WorkName TaskName,w.WorkId
	,CASE WHEN w.WorkLoadUnit=2 THEN  w.WorkLoad ELSE w.WorkLoad/8.00  END WorkLoad
	FROM dbo.LT_WorkHourFill a INNER JOIN dbo.SM_Users b ON a.CreateUser=b.UserId
	INNER JOIN dbo.PJ_WorkPiece w ON a.WorkId=w.WorkId
	INNER JOIN dbo.PJ_WorkPiece p ON w.ProjectId=p.WorkId
	LEFT JOIN Auctus_OA_User c ON b.UserName=c.LastName
	LEFT JOIN ExtendData d ON p.WorkId=d.ObjectId
	LEFT JOIN ExtendData1 d1 ON p.WorkId=d1.ObjectId
	LEFT JOIN ExtendData1 d2 ON p.WorkId=d2.ObjectId
	WHERE PATINDEX('%'+ISNULL(@UserName,'')+'%',b.UserName)>0 AND PATINDEX('%'+ISNULL(@ProjectCode,'')+'%',p.WorkCode)>0  
	AND PATINDEX('%'+ISNULL(@ProjectName,'')+'%',p.WorkName)>0  
	AND c.DepartmentName IN ('研发职能部','硬件部','结构部','软件部','研发分部（泉州）','研发部(上海)','成都预研中心','测试部')
	AND a.FillDate>=@SD AND a.FillDate<@ED
	)
	SELECT a.ProjectID,a.DepartmentName,a.UserName,a.ProjectType,a.ProjectCategory,a.ProjectRelated,a.WorkCode,a.WorkName,SUM(a.FillHour)/8.00 TotalFillHour
	,a.TaskName,MAX(a.WorkLoad)TotalWorkLoad
	FROM data1 a
	GROUP BY a.DepartmentName,a.ProjectID,a.WorkCode,a.WorkName,a.UserName,a.ProjectType,a.ProjectCategory,a.ProjectRelated,a.TaskName

END 

