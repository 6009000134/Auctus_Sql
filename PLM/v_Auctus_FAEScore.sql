/*
FAE-待销售评分任务
*/
CREATE VIEW v_Auctus_FAEScore
as

WITH data1 AS
(
SELECT b.CategoryName,a.WorkId,a.ProjectId,a.WorkCode ProjectCode,a.WorkName ProjectName
FROM dbo.PJ_WorkPiece a INNER JOIN PS_BusinessCategory b ON a.CategoryId=b.CategoryId
WHERE b.CategoryName='FAE项目'
),
ExtendData AS
(
SELECT b.PropertyValue,b.ObjectId,b.ObjectExtendID
	FROM PS_ExtendSettings a INNER JOIN PJ_WorkExtend b ON a.SettingsId=b.SettingsId
	WHERE a.ExtendName='项目大类'
),
SalerData AS
(
SELECT b.PropertyValue,b.ObjectId,b.ObjectExtendID
	FROM PS_ExtendSettings a INNER JOIN PJ_WorkExtend b ON a.SettingsId=b.SettingsId
	WHERE a.ExtendName='销售员'
)
SELECT ou.ID createby--,u.UserName
--s.PropertyValue xsry
,CASE WHEN DATEPART(MONTH,a.ActualEndDate)<5 THEN '151'
ELSE '152' END xsry
,e.PropertyValue xmdl
--,a.ProjectId xmbm
,b.ProjectCode xmbm
,b.ProjectName xmmc
,a.ActualEndDate rq
,a.WorkLoad jhgs,CASE WHEN a.WorkLoadUnit=2 THEN '天' WHEN a.WorkLoadUnit=3 THEN '小时' ELSE ''END jhgsdw
,(SELECT SUM(t.FillHour) FROM dbo.LT_WorkHourFill t WHERE t.WorkId=a.WorkId)ljgs
,a.WorkId rwmc--,a.WorkCode,a.WorkName  
,a.WorkName rwmca--,a.WorkCode,a.WorkName  
--,DENSE_RANK() OVER( ORDER BY s.PropertyValue)RN
,DENSE_RANK() OVER( ORDER BY CASE WHEN DATEPART(MONTH,a.ActualEndDate)<5 THEN '151'
ELSE '152' END)RN
FROM dbo.PJ_WorkPiece a INNER JOIN data1 b ON a.ProjectId=b.WorkId
LEFT JOIN dbo.SM_Users u ON a.Principal=u.UserId LEFT JOIN dbo.Auctus_OA_User ou ON u.UserName=ou.LastName
LEFT JOIN ExtendData e ON b.ProjectId=e.ObjectId
LEFT JOIN SalerData s ON b.ProjectId=s.ObjectId 
--ORDER BY RN,xmbm


GO
