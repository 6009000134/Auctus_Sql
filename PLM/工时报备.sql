--SELECT * FROM dbo.LT_WorkHourFill order by createdate
/*
��߼���PLMĿǰ�߼�����һ��
���ʱ����
��ʱ��Ч����
���ܱ�������Ա�����ź���Ŀ�������
��ϸ�����ӣ���ʱ��Сʱ����
����ȡOA����
*/
SELECT * FROM dbo.PJ_WorkPiece WHERE WorkId='652D2DF7-808E-43F5-8953-4F2068A90014'
SELECT * FROM dbo.PJ_WorkPiece WHERE WorkId='01b54d81-1651-44ce-9c53-6787d36acab9'

SELECT * FROM dbo.PJ_WorkRelation WHERE RelationId='01b54d81-1651-44ce-9c53-6787d36acab9'

SELECT * FROM dbo.PJ_WorkBaseRelation WHERE RelationId='01b54d81-1651-44ce-9c53-6787d36acab9'

--LT_WorkHourFill
SELECT * FROM dbo.v_auctus_ProjectDetail


