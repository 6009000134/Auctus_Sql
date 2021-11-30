/*
��ʱ������ϸ������Ա�����š���Ŀ����
*/
ALTER PROC sp_Auctus_FillHourDetail
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
	WHERE a.ExtendName='��Ŀ����'
	),
	data1 AS
	(
	SELECT 
	c.DepartmentName,p.WorkCode,p.WorkName,b.UserName,a.FillHour,d.PropertyValue ProjectType
	FROM dbo.LT_WorkHourFill a INNER JOIN dbo.SM_Users b ON a.CreateUser=b.UserId
	INNER JOIN dbo.PJ_WorkPiece w ON a.WorkId=w.WorkId
	INNER JOIN dbo.PJ_WorkPiece p ON w.ProjectId=p.WorkId
	LEFT JOIN Auctus_OA_User c ON b.UserName=c.LastName
	LEFT JOIN ExtendData d ON p.WorkId=d.ObjectId
	WHERE PATINDEX('%'+ISNULL(@UserName,'')+'%',b.UserName)>0 AND PATINDEX('%'+ISNULL(@ProjectCode,'')+'%',p.WorkCode)>0  
	AND PATINDEX('%'+ISNULL(@ProjectName,'')+'%',p.WorkName)>0  
	AND c.DepartmentName IN ('�з�ְ�ܲ�','Ӳ����','�ṹ��','�����','Ӳ�������飨Ȫ�ݣ�','Ӳ����(Ȫ��)','����飨Ȫ�ݣ�','��Ŀ�飨Ȫ�ݣ�','�з���(�Ϻ�)','�ɶ�Ԥ������')
	AND a.CreateDate>=@SD AND a.CreateDate<@ED
	)
	SELECT a.DepartmentName,a.UserName,a.ProjectType,a.WorkCode,a.WorkName,SUM(a.FillHour)/8.00 TotalFillHour
	FROM data1 a 
	GROUP BY a.DepartmentName,a.WorkCode,a.WorkName,a.UserName,a.ProjectType

END 