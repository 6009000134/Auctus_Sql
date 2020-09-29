--/*
--备份每日mes排产达成率
--*/
ALTER  PROC [dbo].[sp_Auctus_Mes_DailyRate]
AS
BEGIN
SET NOCOUNT ON 
DECLARE @Date DATE =DATEADD(DAY,-1,GETDATE())

--DECLARE @Date datetime ='2020-09-19'
--DECLARE @Date DATETIME='2020-04-07 09:00:00'
--当天已经备份了数据，不再备份
IF NOT EXISTS(SELECT 1 FROM dbo.Auctus_MesDailyRate WHERE FORMAT(@Date,'yyyy-MM-dd')=PlanDate)
BEGIN
	;WITH PlanData AS
	(
	SELECT 
	a.PlanDate,a.WorkOrder,SUM(a.PlanCount)PlanCount,MIN(a.LineId)LineID
	--,(SELECT ISNULL(SUM(t.PlanCount),0) 
	--FROM MESDATA.au_mes.dbo.mxqh_MoPlanCount t 
	--WHERE t.PlanDate<=a.PlanDate AND t.WorkOrder=a.WorkOrder)TotalPlanCount
	,(ISNULL((SELECT SUM(t.FinishSum) 
	FROM MESDATA.au_mes.dbo.mx_PlanExBackNumMain t 
	INNER JOIN MESDATA.au_mes.dbo.mxqh_plAssemblyPlanDetail t1 ON t.AssemblyPlanDetailID=t1.ID
	WHERE t.OpDate<a.PlanDate AND t1.WorkOrder=a.WorkOrder GROUP BY t1.WorkOrder),0)+ISNULL(SUM(a.PlanCount),0))TotalPlanCount
	FROM MESDATA.au_mes.dbo.mxqh_MoPlanCount a
	WHERE 1=1
	--AND WorkOrder='AMO-30191204001'
	AND  a.PlanDate=FORMAT(@Date,'yyyy-MM-dd')
	GROUP BY a.PlanDate,a.WorkOrder
	HAVING SUM(a.PlanCount)>0--存在排产数量为0的排产计划
	),
	U9Data AS
	(
	SELECT b.DocNo,SUM(a.CompleteQty)CompleteQty
	FROM dbo.MO_CompleteRpt a INNER JOIN dbo.MO_MO b ON a.MO=b.ID
	WHERE a.CreatedOn>@Date
	AND a.CreatedOn<DATEADD(DAY,1,@Date)
	AND a.DocState=3
	GROUP BY b.DocNo
	),
	StartInfo AS
	(
	SELECT t.DocNo,ISNULL(SUM(t.StartQty),0)StartedQty
	FROM (
	SELECT b.DocNo,CASE WHEN a.BusinessDirection=0 THEN a.StartQty ELSE (-1)*a.StartQty END StartQty 
	FROM dbo.MO_MOStartInfo a INNER JOIN dbo.MO_MO b ON a.MO=b.ID
	INNER JOIN PlanData c ON b.DocNo=c.WorkOrder
	WHERE 
	--a.CreatedOn>@Date AND 
	a.CreatedOn<DATEADD(DAY,1,@Date)
	) t GROUP BY t.DocNo
	),
	MOPicks AS
	(
	SELECT t.DocNo,MIN(t.MM)KittingCount
	FROM (
	SELECT a.DocNo,c.DocLineNO,CASE WHEN c.IssuedQty=0 THEN 0 ELSE  c.IssuedQty*a.ProductQty/CONVERT(DECIMAL(18,2),c.ActualReqQty)END MM
	FROM MO_MO a INNER JOIN PlanData b  ON a.DocNo=b.WorkOrder INNER JOIN dbo.MO_MOPickList c ON a.ID=c.MO
	WHERE c.IssueStyle=0
	) t GROUP BY t.DocNo
	)
	INSERT INTO Auctus_MesDailyRate
	SELECT b.Name LineName,hr.Name,a.PlanDate,w.WorkOrder,m.MaterialCode,m.MaterialName,m.Spec,w.Quantity,a.PlanCount,a.TotalPlanCount
	,CONVERT(INT,ISNULL(u.CompleteQty,0))U9CompleteQty
	,CONVERT(INT,CASE WHEN a.PlanCount-ISNULL(u.CompleteQty,0)>=0 THEN a.PlanCount-ISNULL(u.CompleteQty,0) ELSE 0 END )
	UnCompleteQty
	,CONVERT(DECIMAL(18,2),ISNULL(u.CompleteQty,0)/CONVERT(DECIMAL(18,2),a.PlanCount)*100) Rate
	,p.KittingCount,ISNULL(s.StartedQty,0) StartedQty
	,GETDATE() CopyDate
	FROM PlanData a INNER JOIN MESDATA.au_mes.dbo.mxqh_plAssemblyPlanDetail w ON a.WorkOrder=w.WorkOrder
	INNER JOIN MESDATA.au_mes.dbo.mxqh_Material m ON w.MaterialID=m.Id
	LEFT JOIN MESDATA.au_mes.dbo.baAssemblyLine b ON a.LineId=b.ID
	LEFT JOIN MESDATA.au_mes.dbo.hr_User hr ON b.UserID=hr.Id
	LEFT JOIN U9Data u ON w.WorkOrder=u.DocNo
	LEFT JOIN MOPicks p ON a.WorkOrder=p.DocNo
	LEFT JOIN StartInfo s ON a.WorkOrder=s.DocNo

END 

;

SET NOCOUNT OFF

WHILE NOT EXISTS(SELECT 1 FROM dbo.Auctus_MesDailyRate WHERE PlanDate=FORMAT(@Date,'yyyy-MM-dd'))
BEGIN
	IF @Date<'2020-09-01'
	BEGIN
		BREAK;
	END 
	SET @Date=DATEADD(DAY,-1,@Date)
	IF EXISTS(SELECT 1 FROM dbo.Auctus_MesDailyRate WHERE PlanDate=FORMAT(@Date,'yyyy-MM-dd'))
	BEGIN
		BREAK;
	END 
END	

SELECT  TOP 1 1 MailNo, 'BDPRecipients@auctus.cn' AS MailTo, 'DailyRate.xml' AS  XmlName, '刘飞' CHI_NAME, 'dddsfal' FORM_TYPE		
--SELECT  TOP 1 1 MailNo, 'liufei@auctus.com' AS MailTo, 'DailyRate.xml' AS  XmlName, '刘飞' CHI_NAME, 'dddsfal' FORM_TYPE		
,FORMAT(@Date,'yyyy-MM-dd')NowDate,DATENAME(WEEKDAY,@Date)WD

SELECT 1 MailNo
,a.LineName,a.Name,a.PlanDate,a.WorkOrder,a.MaterialCode,a.MaterialName,a.Spec,a.Quantity,a.PlanCount
,a.TotalPlanCount,a.U9CompleteQty,a.UnCompleteQty,a.Rate
,CASE WHEN StartedQty-CASE WHEN a.TotalPlanCount>a.Quantity THEN a.Quantity ELSE a.TotalPlanCount END>=0 THEN '齐套'
ELSE '不齐套' END IsKitting
,CASE WHEN StartedQty-CASE WHEN a.TotalPlanCount>a.Quantity THEN a.Quantity ELSE a.TotalPlanCount END>=0 THEN ''
ELSE 'background:red;' END IsKittingStyle
,ROW_NUMBER()OVER(ORDER BY a.LineName)RN
FROM Auctus_MesDailyRate a WHERE a.PlanDate=FORMAT(@Date,'yyyy-MM-dd')
	
END 

