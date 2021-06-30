ALTER  VIEW  [dbo].[v_PJ_WorkPlan] 
AS SELECT 
a.RelationId as RelationId
,a.RelationType as RelationType
,a.ProjectId as ProjectId
,b.WorkId as WorkId
,b.WorkCode as WorkCode
,b.WorkName as WorkName
,d.UserName as  UserName
,b.PlanStartDate as PlanStartDate
,b.PlanEndDate as PlanEndDate
,c.CategoryName as CategoryName
,a.SequenceNO
FROM dbo.PJ_WorkRelation a INNER JOIN dbo.PJ_WorkPiece b ON a.ChildWork=b.WorkId
INNER JOIN dbo.PS_BusinessCategory c ON b.CategoryId=c.CategoryId
AND a.RelationType!=3
INNER JOIN dbo.SM_Users d ON b.Principal=d.UserId
WHERE b.State!=2 
--AND NOT EXISTS (SELECT 1 FROM dbo.PJ_WorkRelation t WHERE t.ParentWork=b.WorkId)


GO
