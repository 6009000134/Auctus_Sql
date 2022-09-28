SELECT  1 MailNo, 'zhangwei@auctus.cn,liuky@auctus.cn,wugx@auctus.cn,chenxt@auctus.cn,zhangxr@auctus.cn,lisl@auctus.cn,xiaoli@auctus.com,yangcf@auctus.cn,wangping@auctus.cn,xiongtao@auctus.cn,guohz@auctus.cn,zhuyong@auctus.cn,chenll@auctus.cn' AS MailTo, 'TaskInfo.xml' AS  XmlName
,DATENAME(WEEKDAY,CASE 
WHEN DATEPART(WEEKDAY,GETDATE())=6 THEN DATEADD(DAY,3,GETDATE()) 
WHEN DATEPART(WEEKDAY,GETDATE())=7 THEN DATEADD(DAY,2,GETDATE()) 
ELSE DATEADD(DAY,1,CONVERT(DATE,GETDATE())) END) DateName
,format(CASE 
WHEN DATEPART(WEEKDAY,GETDATE())=6 THEN DATEADD(DAY,3,GETDATE()) 
WHEN DATEPART(WEEKDAY,GETDATE())=7 THEN DATEADD(DAY,2,GETDATE()) 
ELSE DATEADD(DAY,1,CONVERT(DATE,GETDATE())) END,'yyyy-MM-dd') Date
,'下个工作日任务列表'TITLE

SELECT
1 MailNo,b.WorkCode ProjectCode,b.WorkName ProjectName,a.WorkId,a.WorkCode,a.WorkName,u.UserName
,a.PlanStartDate,a.ActualStartDate,a.PlanEndDate,a.ActualEndDate
,o.DepartmentName
,CASE WHEN a.State=0 THEN '初始化' WHEN a.State=1 THEN '启动' ELSE '' END State
FROM dbo.PJ_WorkPiece a  
LEFT JOIN dbo.PJ_WorkPiece b ON a.ProjectId=b.WorkId
LEFT JOIN dbo.SM_Users u ON a.Principal=u.UserId
LEFT JOIN dbo.PJ_Project p ON b.WorkId=p.WorkId
LEFT JOIN dbo.Auctus_OA_User o ON u.UserName=o.LastName
WHERE a.State!=2 AND a.ProjectId!=''
AND a.IsFreeze=0
AND  CASE WHEN DATEPART(WEEKDAY,GETDATE())=6 THEN DATEADD(DAY,3,CONVERT(DATE,GETDATE())) WHEN DATEPART(WEEKDAY,GETDATE())=7 THEN DATEADD(DAY,2,CONVERT(DATE,GETDATE())) ELSE DATEADD(DAY,1,CONVERT(DATE,GETDATE())) END >=CONVERT(DATE,a.PlanStartDate)
AND CASE WHEN DATEPART(WEEKDAY,GETDATE())=6 THEN DATEADD(DAY,3,CONVERT(DATE,GETDATE())) WHEN DATEPART(WEEKDAY,GETDATE())=7 THEN DATEADD(DAY,2,CONVERT(DATE,GETDATE())) ELSE DATEADD(DAY,1,CONVERT(DATE,GETDATE())) END <=CONVERT(DATE,a.PlanEndDate)
AND NOT EXISTS(SELECT parentwork FROM dbo.PJ_WorkRelation r WHERE r.ParentWork=a.WorkId AND r.RelationType=2)
AND PATINDEX('执行性项目事务%',p.FilePath)=0
ORDER BY o.DepartmentName,u.UserName