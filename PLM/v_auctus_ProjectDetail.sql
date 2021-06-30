--TODO:SS FS FF FS
alter VIEW v_auctus_ProjectDetail
AS


WITH data1 AS
(
SELECT a.RelationId,a.RelationType,b.ProjectId,a.ParentWork,a.ChildWork,a.SequenceNO,a.DisplaySeq,1 Lv FROM dbo.PJ_WorkRelation a 
INNER JOIN dbo.PJ_WorkPiece b ON a.ParentWork=b.WorkId
WHERE a.SequenceNO>0
),
AllRelation AS
(
SELECT a.RelationId,a.RelationType,a.ParentWork,a.ChildWork,a.SequenceNO,a.DisplaySeq,a.Lv FROM data1 a WHERE a.ProjectId=''--WHERE a.ParentWork='28C3542C-1D0A-4BD3-9806-0083616FA505'
UNION ALL
SELECT b.RelationId,b.RelationType,a.ParentWork,b.ChildWork,b.SequenceNO,b.DisplaySeq,a.Lv+1 FROM AllRelation a INNER JOIN data1 b ON a.ChildWork=b.ParentWork
WHERE a.RelationType!=3
)
SELECT 
t2.RelationId
,t2.RelationType
,t2.ParentWork
,t2.ChildWork
,t2.DisplaySeq
,t2.SequenceNO
,t2.ProjectCode
,t2.ProjectName--项目名称
,t2.WorkCode
,t2.WorkName--阶段任务名称
,t2.NormalLimit--正常工期
,t2.PlanStartDate--计划开始时间
,t2.PlanEndDate--计划结束时间 
,LEFT(t2.PreWork,LEN(t2.PreWork)-1)PreWork
,t2.State
FROM (
SELECT a.RelationId,A.RelationType,a.ParentWork,a.ChildWork,a.DisplaySeq,a.SequenceNO
,b.WorkCode ProjectCode,b.WorkName ProjectName--项目名称
,b.State
,c.WorkCode,c.WorkName--阶段任务名称
,c.NormalLimit--正常工期
,c.PlanStartDate--计划开始时间
,c.PlanEndDate--计划结束时间
--,d1.SequenceNO PreWork--前置任务
,(SELECT 
CASE WHEN t.DelayTime>0 THEN CONVERT(VARCHAR(100),t1.SequenceNO)+CASE WHEN t.ExecuteMode=0 THEN '' WHEN t.ExecuteMode=1 THEN 'FF' WHEN t.ExecuteMode=2 THEN 'SS' WHEN t.ExecuteMode=3 THEN 'SF' END+'+'+FORMAT(t.DelayTime,'##')+CASE WHEN t.DelayTimeUnit=2 THEN 'd' ELSE 'h'end+',' 
WHEN t.DelayTime<0 THEN CONVERT(VARCHAR(100),t1.SequenceNO)+CASE WHEN t.ExecuteMode=0 THEN '' WHEN t.ExecuteMode=1 THEN 'FF' WHEN t.ExecuteMode=2 THEN 'SS' WHEN t.ExecuteMode=3 THEN 'SF' END+'-'+FORMAT(t.DelayTime,'##')+CASE WHEN t.DelayTimeUnit=2 THEN 'd' ELSE 'h'end+',' 
ELSE  CONVERT(VARCHAR(100),t1.SequenceNO)+','end
FROM dbo.PJ_WorkRelation t1 INNER JOIN dbo.PJ_WorkRelation t ON t1.ChildWork=t.ParentWork AND t1.RelationType!=3 AND t.RelationType=3 
AND t1.ProjectId=c.ProjectId AND t.ProjectID=c.ProjectId AND t.ChildWork=a.ChildWork
FOR XML PATH('')) PreWork
FROM AllRelation a INNER JOIN dbo.PJ_WorkPiece b ON a.ParentWork=b.WorkId
INNER JOIN dbo.PJ_WorkPiece c ON a.ChildWork=c.WorkId
)
t2
--WHERE b.WorkCode='LS138'
--ORDER BY a.DisplaySeq