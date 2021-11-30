/*
工时报备汇总，按部门汇总
*/
ALTER PROC sp_Auctus_FillHourTotalByDept
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
	data1 AS
	(
	SELECT 
	p.WorkCode,p.WorkName,d.PropertyValue ProjectType,ISNULL(c.DepartmentName,'无')DepartmentName,SUM(a.FillHour)/8.00 FillHours
	FROM dbo.LT_WorkHourFill a INNER JOIN dbo.SM_Users b ON a.CreateUser=b.UserId
	INNER JOIN dbo.PJ_WorkPiece w ON a.WorkId=w.WorkId
	INNER JOIN dbo.PJ_WorkPiece p ON w.ProjectId=p.WorkId
	LEFT JOIN Auctus_OA_User c ON b.UserName=c.LastName
	LEFT JOIN ExtendData d ON p.WorkId=d.ObjectId
	WHERE PATINDEX('%'+ISNULL(@UserName,'')+'%',b.UserName)>0 AND PATINDEX('%'+ISNULL(@ProjectCode,'')+'%',p.WorkCode)>0  
	AND PATINDEX('%'+ISNULL(@ProjectName,'')+'%',p.WorkName)>0  
	AND a.CreateDate>=@SD AND a.CreateDate<@ED
	GROUP BY p.WorkName,p.WorkCode,c.DepartmentName,d.PropertyValue
	)
	SELECT  * 
	FROM data1 a 
	PIVOT (MIN(FillHours) FOR DepartmentName IN([研发职能部],[硬件部],[结构部],[软件部],[硬件测试组（泉州）],[硬件组(泉州)],[软件组（泉州）],[项目组（泉州）],[研发部(上海)],[成都预研中心]))t


END 