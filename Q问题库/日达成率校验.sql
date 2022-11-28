
DECLARE @Date DATETIME ='2020-12-04'

--DECLARE @Date datetime ='2020-09-19'
--DECLARE @Date DATETIME='2020-04-07 09:00:00'
--当天已经备份了数据，不再备份

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
	,(SELECT SUM(t.ProRepairSum) FROM MESDATA.au_mes.dbo.mx_PlanExBackNumData t 
	INNER JOIN MESDATA.au_mes.dbo.mxqh_plAssemblyPlanDetail t1 ON t.AssemblyPlanDetailID=t1.ID
	WHERE t1.WorkOrder=a.WorkOrder GROUP BY t1.WorkOrder)RepairNum
	FROM MESDATA.au_mes.dbo.mxqh_MoPlanCount a
	WHERE 1=1
	AND WorkOrder='MO-30201203003'
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
	AND b.DocNo='MO-30201203003'
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
SELECT * FROM (
	SELECT t.DocNo,MIN(t.MM)KittingCount,t.ItemFormAttribute
	FROM (
	SELECT a.DocNo,c.DocLineNO,CASE WHEN c.IssuedQty=0 THEN 0 ELSE  c.IssuedQty*a.ProductQty/CONVERT(DECIMAL(18,2),c.ActualReqQty)END MM
	,'KittingCount'+CONVERT(VARCHAR(10),m.ItemFormAttribute) ItemFormAttribute
	FROM MO_MO a INNER JOIN PlanData b  ON a.DocNo=b.WorkOrder INNER JOIN dbo.MO_MOPickList c ON a.ID=c.MO	
	LEFT JOIN dbo.CBO_ItemMaster m ON c.ItemMaster=m.ID
	WHERE c.IssueStyle=0 AND m.ItemFormAttribute IN (9,10)
	AND c.ActualReqQty>0
	) t GROUP BY t.DocNo,t.ItemFormAttribute) t1 PIVOT (MIN(t1.KittingCount) FOR ItemFormAttribute IN (KittingCount9,KittingCount10)) AS tt
	),
	MOArrange AS
    (
	SELECT a.ArrangeDate,a.WorkOrder,b.HrUserName
FROM MESDATA.au_mes.dbo.mxqh_MoLineArrange a INNER JOIN MESDATA.au_mes.dbo.mxqh_MoLineArrangeDtl b ON a.Id=b.ArrangeId
WHERE b.EmpType='L'
	)
	SELECT b.Name LineName,ISNULL(ma.HrUserName,hr.Name)Name,a.PlanDate,w.WorkOrder,m.MaterialCode,m.MaterialName,m.Spec,w.Quantity,a.PlanCount,a.TotalPlanCount
	,CONVERT(INT,ISNULL(u.CompleteQty,0))U9CompleteQty
	,CONVERT(INT,CASE WHEN a.PlanCount-ISNULL(u.CompleteQty,0)-ISNULL(a.RepairNum,0)>=0 THEN a.PlanCount-ISNULL(u.CompleteQty,0)-ISNULL(a.RepairNum,0) ELSE 0 END )
	UnCompleteQty
	,CONVERT(DECIMAL(18,2),(ISNULL(u.CompleteQty,0)+ISNULL(a.RepairNum,0))/CONVERT(DECIMAL(18,2),a.PlanCount)*100) Rate
	,p.KittingCount9,p.KittingCount10,ISNULL(a.RepairNum,0),ISNULL(s.StartedQty,0) StartedQty
	,GETDATE() CopyDate
	FROM PlanData a INNER JOIN MESDATA.au_mes.dbo.mxqh_plAssemblyPlanDetail w ON a.WorkOrder=w.WorkOrder
	INNER JOIN MESDATA.au_mes.dbo.mxqh_Material m ON w.MaterialID=m.Id
	LEFT JOIN MOArrange ma ON a.WorkOrder=ma.WorkOrder AND a.PlanDate=ma.ArrangeDate
	LEFT JOIN MESDATA.au_mes.dbo.baAssemblyLine b ON a.LineId=b.ID
	LEFT JOIN MESDATA.au_mes.dbo.hr_User hr ON b.UserID=hr.Id
	LEFT JOIN U9Data u ON w.WorkOrder=u.DocNo
	LEFT JOIN MOPicks p ON a.WorkOrder=p.DocNo
	LEFT JOIN StartInfo s ON a.WorkOrder=s.DocNo

	SELECT a.DocNo,b.CompleteDate 完工日期,b.CreatedOn 创建日期,b.DocNo,b.CompleteQty 完工数,b.ApproveOn 审核日期
	FROM mo_mo a INNER JOIN dbo.MO_CompleteRpt b ON a.ID=b.MO 
	WHERE a.DocNo IN ('MO-30201203003','MO-30201104013','MO-30201104014','MO-30201026009')

	