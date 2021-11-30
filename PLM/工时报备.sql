--SELECT * FROM dbo.LT_WorkHourFill order by createdate
/*
填报逻辑与PLM目前逻辑保持一致
填报工时上限
工时绩效样表
汇总报表：按人员、部门和项目大类汇总
明细表增加：工时（小时）列
部门取OA部门
*/
SELECT * FROM dbo.PJ_WorkPiece WHERE WorkId='652D2DF7-808E-43F5-8953-4F2068A90014'
SELECT * FROM dbo.PJ_WorkPiece WHERE WorkId='01b54d81-1651-44ce-9c53-6787d36acab9'

SELECT * FROM dbo.PJ_WorkRelation WHERE RelationId='01b54d81-1651-44ce-9c53-6787d36acab9'

SELECT * FROM dbo.PJ_WorkBaseRelation WHERE RelationId='01b54d81-1651-44ce-9c53-6787d36acab9'

--LT_WorkHourFill
SELECT * FROM dbo.v_auctus_ProjectDetail


