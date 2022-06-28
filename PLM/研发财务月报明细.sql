/*
研发财务月报明细
*/
ALTER VIEW v_Auctus_RDFinanceReport
as

WITH MonthData AS
(
SELECT DISTINCT SUBSTRING(FillDate,1,7)CalMonth FROM dbo.LT_WorkHourFill
),
ProjectInfo AS
(
SELECT a.ActualStartDate,a.WorkCode ProjectCode,a.WorkName ProjectName,a.WorkId ProjectID,SUBSTRING(a.ActualStartDate,1,4)StartYear
--,SUBSTRING(a.ActualStartDate,1,7)MM
--,SUBSTRING(a.ActualEndDate,1,7)MMzm
--,SUBSTRING((CASE WHEN a.ActualEndDate='' THEN CONVERT(VARCHAR(19),GETDATE(),121) ELSE a.ActualEndDate END),1,7)jj
,b.CalMonth
FROM dbo.PJ_WorkPiece a,MonthData b  WHERE 1=1 
AND a.State=1 AND a.WorkCode='AU114'
AND b.CalMonth>=SUBSTRING(a.ActualStartDate ,1,7) AND b.CalMonth<=SUBSTRING((CASE WHEN a.ActualEndDate='' THEN CONVERT(VARCHAR(19),GETDATE(),121) ELSE a.ActualEndDate END),1,7)
AND ISNULL(a.ProjectId,'')=''
),
WorkHours AS
(
SELECT c.StartYear,c.ProjectID,c.ProjectCode,c.ProjectName,c.CalMonth ,SUM(a.FillHour)/8.00 FillDays
,ou.DepartmentName,ou.DepartmentID
,ROW_NUMBER()OVER(ORDER BY c.ProjectCode,c.CalMonth,ou.DepartmentName)RN
FROM  ProjectInfo c LEFT JOIN 
(SELECT t.ProjectId,t1.FillDate,t1.FillHour,t1.CreateUser FROM dbo.PJ_WorkPiece t INNER JOIN dbo.LT_WorkHourFill t1 ON t.WorkId=t1.WorkId)
a ON c.ProjectID=a.ProjectId AND SUBSTRING(a.FillDate,1,7)<=c.CalMonth
--LEFT JOIN dbo.LT_WorkHourFill a  ON b.WorkId=a.WorkId AND SUBSTRING(a.FillDate,1,7)<=c.CalMonth
LEFT JOIN dbo.SM_Users u ON a.CreateUser=u.UserId
LEFT JOIN Auctus_OA_User ou ON u.UserName=ou.LastName
WHERE 1=1
AND c.ProjectCode IN ('AU114','ZD005','LT002')
AND ISNULL(ou.DepartmentName,'无') IN ('研发职能部','硬件部','结构部','软件部','测试部','研发分部（泉州）','研发部(上海)','成都预研中心')	
GROUP BY c.StartYear,c.ProjectID,c.ProjectCode,c.ProjectName,c.CalMonth,ou.DepartmentName,ou.DepartmentID
),
AllHours AS
(
SELECT * FROM WorkHours 
UNION ALL
SELECT MIN(a.StartYear),a.ProjectID,a.ProjectCode,a.ProjectName,a.CalMonth,SUM(a.FillDays),'汇总',MAX(rn)+1 DepartmentName,99999 DepartmentID 
FROM WorkHours a GROUP BY a.ProjectID,a.ProjectCode,a.ProjectName,a.CalMonth
),
NREData AS
(
SELECT a.yjgst+a.rjgst+a.jggst+a.csgst+a.rcgst+a.ycgst TotalBudgetDay,a.yfrlf SalaryBudget,a.xmjjf BonusBudget
,a.yfrlf+a.xmjjf TotalBudget,a.xmbm
FROM dbo.Auctus_ProjectBudget a
--SELECT a.xmbm,a.ffyf,SUM(a.jjje)jjje FROM dbo.Auctus_ProjectBonus a
--GROUP BY a.xmbm,a.ffyf
),
SalaryInfo AS
(
SELECT a.sjpjgz,modedatacreateddate FROM Auctus_Salary  a
WHERE a.modedatacreateddate=(SELECT MAX(modedatacreateddate) FROM Auctus_Salary)
)
SELECT 
a.ProjectID+CONVERT(VARCHAR(20),a.DepartmentID)+a.CalMonth ID
,a.ProjectCode
,a.StartYear
,a.CalMonth
,a.DepartmentName
,b.TotalBudgetDay
,b.SalaryBudget
,b.BonusBudget
,b.TotalBudget
,(SELECT SUM(CASE WHEN t.NormalLimitUnitName='小时' THEN t.NormalLimit/8.00 ELSE t.NormalLimit END ) FROM v_auctus_ProjectDetail t WHERE t.ProjectCode=a.ProjectCode AND t.PlanStartDate<DATEADD(MONTH,1,a.CalMonth+'-01'))TotalWorkLoad
,CONVERT(VARCHAR(20),CONVERT(DECIMAL(18,2),(SELECT SUM(CASE WHEN t.NormalLimitUnitName='小时' THEN t.NormalLimit/8.00 ELSE t.NormalLimit END ) FROM v_auctus_ProjectDetail t WHERE t.ProjectCode=a.ProjectCode AND t.PlanStartDate<DATEADD(MONTH,1,a.CalMonth+'-01'))/b.TotalBudgetDay*100))+'%' ProgressRate
,b.TotalBudget*(SELECT SUM(CASE WHEN t.NormalLimitUnitName='小时' THEN t.NormalLimit/8.00 ELSE t.NormalLimit END ) FROM v_auctus_ProjectDetail t WHERE t.ProjectCode=a.ProjectCode AND t.PlanStartDate<DATEADD(MONTH,1,a.CalMonth+'-01'))/b.TotalBudgetDay UsageBudget
,a.FillDays--实际填报工时
,(SELECT sjpjgz FROM dbo.Auctus_Salary WHERE modedatacreateddate=(SELECT MAX(modedatacreateddate) FROM dbo.Auctus_Salary))ActualSalary
,a.FillDays*(SELECT sjpjgz FROM dbo.Auctus_Salary WHERE modedatacreateddate=(SELECT MAX(modedatacreateddate) FROM dbo.Auctus_Salary))ActualTotalSalary
--,c.jjje ActualBonus
,(SELECT sum(t.jjje) FROM Auctus_ProjectBonus t WHERE t.xmbm=a.ProjectID AND t.ffyf<=a.CalMonth)ActualBonus
,a.FillDays*(SELECT sjpjgz FROM dbo.Auctus_Salary WHERE modedatacreateddate=(SELECT MAX(modedatacreateddate) FROM dbo.Auctus_Salary))
+(SELECT sum(t.jjje) FROM Auctus_ProjectBonus t WHERE t.xmbm=a.ProjectID AND t.ffyf<=a.CalMonth)ActualTotalMoney
,CONVERT(VARCHAR(20),CONVERT(DECIMAL(18,2),(a.FillDays*(SELECT sjpjgz FROM dbo.Auctus_Salary WHERE modedatacreateddate=(SELECT MAX(modedatacreateddate) FROM dbo.Auctus_Salary))+(SELECT sum(t.jjje) FROM Auctus_ProjectBonus t WHERE t.xmbm=a.ProjectID AND t.ffyf<=a.CalMonth))/b.TotalBudget)*100)+'%' BudgetRate
,CONVERT(VARCHAR(20),CONVERT(DECIMAL(18,2),(a.FillDays*(SELECT sjpjgz FROM dbo.Auctus_Salary WHERE modedatacreateddate=(SELECT MAX(modedatacreateddate) FROM dbo.Auctus_Salary))+(SELECT sum(t.jjje) FROM Auctus_ProjectBonus t WHERE t.xmbm=a.ProjectID AND t.ffyf<=a.CalMonth))/b.TotalBudget*(SELECT SUM(CASE WHEN t.NormalLimitUnitName='小时' THEN t.NormalLimit/8.00 ELSE t.NormalLimit END ) FROM v_auctus_ProjectDetail t WHERE t.ProjectCode=a.ProjectCode AND t.PlanStartDate<DATEADD(MONTH,1,a.CalMonth+'-01'))/b.TotalBudgetDay)*100)+'%' CompareRate--实际与预算进度比较
--,b.*
,ROW_NUMBER() OVER(ORDER BY a.ProjectCode,a.CalMonth,a.RN)OrderNo
FROM AllHours a LEFT JOIN NREData b ON a.ProjectID=b.xmbm


--ORDER BY a.ProjectCode,a.FillMonth,a.RN


--SELECT * FROM dbo.v_auctus_ProjectDetail WHERE ProjectCode='AU114' AND PlanStartDate<'2018-10-01'
--INSERT INTO dbo.Auctus_ProjectBonus
--        ( ID ,
--          xmbm ,
--          jjje ,
--          ffyf ,
--          modedatacreater ,
--          modedatacreateddate ,
--          modedatamodifier ,
--          modedatamodifydate
--        )
--VALUES  ( 10 , -- ID - int
--          'D5D81C92-D7B6-4E5A-BBF5-6C64681A99A5' , -- xmbm - varchar(50)
--          212000 , -- jjje - decimal(18, 2)
--          '2018-11' , -- ffyf - varchar(10)
--          '' , -- modedatacreater - varchar(20)
--          GETDATE() , -- modedatacreateddate - datetime
--          '' , -- modedatamodifier - varchar(20)
--          GETDATE()  -- modedatamodifydate - datetime
--        )
--SELECT * FROM dbo.Auctus_ProjectBonus
--SELECT * FROM dbo.Auctus_ProjectBudget
--SELECT * FROM dbo.Auctus_Salary
--SELECT b.WorkCode,a.* 
--FROM dbo.Auctus_ProjectBudget a INNER JOIN dbo.PJ_WorkPiece b ON a.xmbm=b.WorkId
--D5D81C92-D7B6-4E5A-BBF5-6C64681A99A5	AU114

--INSERT INTO dbo.Auctus_ProjectBudget
--        ( ID ,
--          xmbm ,
--          yjgst ,
--          rjgst ,
--          jggst ,
--          csgst ,
--          yszgst ,
--          sbf ,
--          dyscf ,
--          zjf ,
--          ycsf ,
--          zsrzf ,
--          altcsf ,
--          scf ,
--          yfrlf ,
--          xmjjf ,
--          modedatacreater ,
--          modedatacreateddate ,
--          modedatamodifier ,
--          modedatamodifydate ,
--          rcgst ,
--          ycgst ,
--          qtfy
--        )select

--ID+1 ,
--          'D5D81C92-D7B6-4E5A-BBF5-6C64681A99A5' ,
--          yjgst ,
--          rjgst ,
--          jggst ,
--          csgst ,
--          yszgst ,
--          sbf ,
--          dyscf ,
--          zjf ,
--          ycsf ,
--          zsrzf ,
--          altcsf ,
--          scf ,
--          yfrlf ,
--          xmjjf ,
--          modedatacreater ,
--          modedatacreateddate ,
--          modedatamodifier ,
--          modedatamodifydate ,
--          rcgst ,
--          ycgst ,
--          qtfy


--FROM dbo.Auctus_ProjectBudget WHERE id=7
