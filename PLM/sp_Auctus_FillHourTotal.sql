/*
工时报备汇总，按人员、部门汇总
*/
ALTER PROC sp_Auctus_FillHourTotal
(
@UserName VARCHAR(50),
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
	data1 AS
	(
	SELECT 
	c.DepartmentName,b.UserName,a.FillHour,d.PropertyValue ProjectType
	FROM dbo.LT_WorkHourFill a INNER JOIN dbo.SM_Users b ON a.CreateUser=b.UserId
	INNER JOIN dbo.PJ_WorkPiece w ON a.WorkId=w.WorkId
	INNER JOIN dbo.PJ_WorkPiece p ON w.ProjectId=p.WorkId
	LEFT JOIN Auctus_OA_User c ON b.UserName=c.LastName
	LEFT JOIN ExtendData d ON p.WorkId=d.ObjectId
	WHERE PATINDEX('%'+ISNULL(@UserName,'')+'%',b.UserName)>0   AND
	c.DepartmentName IN ('研发职能部','硬件部','结构部','软件部','硬件测试组（泉州）','硬件组(泉州)','软件组（泉州）','项目组（泉州）','研发部(上海)','成都预研中心')
	AND a.CreateDate>=@SD AND a.CreateDate<@ED
	)
	SELECT a.DepartmentName,a.UserName,a.ProjectType,SUM(a.FillHour)/8.00 TotalFillHour
	FROM data1 a 
	GROUP BY a.DepartmentName,a.UserName,a.ProjectType

END 