USE [PLM]
GO

/****** Object:  View [dbo].[v_Auctus_ProjectMileStoneMail]    Script Date: 2022/10/27 14:39:05 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/*
PLM��Ŀ��̱������ʼ�����
������Ŀ��̱����ڵ�����δ����ʱ�������ʼ�����Ӧ������Ա,������moto�̶����͸���Ц�ں�������
*/
;
ALTER VIEW [dbo].[v_Auctus_ProjectMileStoneMail]
AS

WITH CustomerData AS
(
SELECT b.PropertyValue,b.ObjectId,b.ObjectExtendID,a.CategoryId
FROM PS_ExtendSettings a INNER JOIN PJ_WorkExtend b ON a.SettingsId=b.SettingsId
WHERE a.ExtendName='�ͻ�'
),
SalerData AS
(
SELECT b.PropertyValue,b.ObjectId,b.ObjectExtendID,a.CategoryId
FROM PS_ExtendSettings a INNER JOIN PJ_WorkExtend b ON a.SettingsId=b.SettingsId
WHERE a.ExtendName='����Ա'
),data1 AS
(
SELECT b.ParentWork,b.ChildWork
FROM dbo.PJ_WorkPiece a INNER JOIN dbo.PJ_WorkRelation b ON a.WorkId=b.ParentWork
WHERE ISNULL(a.ProjectId,'')='' --AND a.WorkId IN('4125055B-25D8-4207-948A-7A1B1076AA5C','8091BD42-B097-4548-92DB-CD3F8125E5C4')
),
Projects AS
(
SELECT DISTINCT b.ParentWork,'1'IsProject FROM dbo.PJ_WorkPiece a INNER JOIN dbo.PJ_WorkRelation b ON a.WorkId=b.ParentWork
WHERE ISNULL(a.ProjectId,'')='' 
),
data2 AS
(
SELECT a.*,ISNULL(b.IsProject,'0')IsProject
FROM data1 a LEFT JOIN Projects b ON a.ChildWork=b.ParentWork
),
data3 AS
(
SELECT a.ParentWork,a.ChildWork,a.RelationType,ISNULL(b.IsProject,'0')IsProject
FROM PJ_WorkRelation a LEFT JOIN Projects b ON a.ChildWork=b.ParentWork
),
pcs AS
(
SELECT a.ParentWork PID,a.ChildWork CID,a.IsProject FROM data2 a
UNION ALL
SELECT a.PID,b.ChildWork CID,b.IsProject IsProject 
FROM pcs a 
INNER JOIN data3 b ON a.CID=b.ParentWork AND b.RelationType IN (0,2) AND a.IsProject='0'
),
ProjectInfo AS
(
SELECT a.PID--,b.Principal,b.Priority,b.CategoryId,b.WorkCode ProjectCode,b.WorkName ProjectName
,c.WorkName
,c.PlanStartDate,c.ActualStartDate
--,a.Customer,a.Saler,a.state
FROM pcs a LEFT JOIN dbo.PJ_WorkPiece b ON a.PID=b.WorkId LEFT JOIN dbo.PJ_WorkPiece c ON a.CID=c.WorkId
WHERE 1=1
AND c.WorkName IN ('����ʱ��','Alpha����','Beta����','ת��������','Seedstock����','��������','ת������','��������')
),
UnDos AS
(
SELECT DISTINCT a.PID FROM ProjectInfo a WHERE ISNULL(a.ActualStartDate,'')=''
AND CONVERT(DATE,a.PlanStartDate)<=CONVERT(DATE,GETDATE())
),
PivotData AS
(
SELECT a.PID--,a.Principal,a.ProjectCode,a.ProjectName,a.Priority,a.CategoryId,a.Customer,a.Saler,a.state
,CASE WHEN a.WorkName='����ʱ��' OR a.WorkName='��������' THEN a.PlanStartDate END '����ʱ��' 
,CASE WHEN a.WorkName='Alpha����' THEN a.PlanStartDate END 'Alpha����' 
,CASE WHEN a.WorkName='Beta����' THEN a.PlanStartDate END 'Beta����' 
,CASE WHEN a.WorkName='ת��������' OR a.WorkName='ת������' THEN a.PlanStartDate END 'ת��������' 
,CASE WHEN a.WorkName='Seedstock����' OR a.WorkName='��������' THEN a.PlanStartDate END 'Seedstock����' 
,CASE WHEN a.WorkName='����ʱ��' OR a.WorkName='��������' THEN a.ActualStartDate END '����ʱ��2' 
,CASE WHEN a.WorkName='Alpha����' THEN a.ActualStartDate END 'Alpha����2' 
,CASE WHEN a.WorkName='Beta����' THEN a.ActualStartDate END 'Beta����2' 
,CASE WHEN a.WorkName='ת��������' OR a.WorkName='ת������' THEN a.ActualStartDate END 'ת��������2' 
,CASE WHEN a.WorkName='Seedstock����' OR a.WorkName='��������' THEN a.ActualStartDate END 'Seedstock����2' 
FROM ProjectInfo a
),
WorkPieces AS
(
SELECT a.PID
,MIN(a.����ʱ��)����ʱ��,MIN(a.Alpha����)Alpha����,MIN(a.Beta����)Beta����,MIN(a.ת��������)ת��������,MIN(a.Seedstock����)Seedstock���� 
,MIN(a.����ʱ��2)����ʱ��2,MIN(a.Alpha����2)Alpha����2,MIN(a.Beta����2)Beta����2,MIN(a.ת��������2)ת��������2,MIN(a.Seedstock����2)Seedstock����2
FROM PivotData a GROUP BY a.PID
)
SELECT a.PID,w.WorkCode ProjectCode,w.WorkName ProjectName
--,cus.PropertyValue Customer
,CASE WHEN PATINDEX('%����%',sd.PropertyValue)=0 AND PATINDEX('%moto%',sd.PropertyValue)=0  THEN  sd.PropertyValue ELSE '����' END  Saler
,'��ͬ�ɷ�asd' Customer
--,CASE WHEN PATINDEX('%����%',sd.PropertyValue)=0 AND PATINDEX('%moto%',sd.PropertyValue)=0  THEN  '����' ELSE '����' END  Saler
,CASE WHEN w.IsFreeze=1 THEN '����' WHEN  w.State=0 THEN '��ʼ��' WHEN w.State=1 THEN '����' WHEN w.State=2 THEN '���' END State
,b.UserName Principal,c.CategoryName,sv.OptionName
,FORMAT(CONVERT(DATETIME,a.����ʱ��),'yyyy-MM-dd')����ʱ��
,FORMAT(CONVERT(DATETIME,a.Alpha����),'yyyy-MM-dd')Alpha����
,FORMAT(CONVERT(DATETIME,a.Beta����),'yyyy-MM-dd')Beta����
,FORMAT(CONVERT(DATETIME,a.ת��������),'yyyy-MM-dd')ת��������
,FORMAT(CONVERT(DATETIME,a.Seedstock����),'yyyy-MM-dd')Seedstock����
,CASE WHEN ISNULL(a.����ʱ��2,'')='' THEN NULL ELSE FORMAT(CONVERT(DATETIME,a.����ʱ��2),'yyyy-MM-dd')END ʵ������ʱ��
,CASE WHEN ISNULL(a.Alpha����2,'')='' THEN NULL ELSE FORMAT(CONVERT(DATETIME,a.Alpha����2),'yyyy-MM-dd')END ʵ��Alpha����
,CASE WHEN ISNULL(a.Beta����2,'')='' THEN NULL ELSE FORMAT(CONVERT(DATETIME,a.Beta����2),'yyyy-MM-dd')END ʵ��Beta����
,CASE WHEN ISNULL(a.ת��������2,'')='' THEN NULL ELSE FORMAT(CONVERT(DATETIME,a.ת��������2),'yyyy-MM-dd')END ʵ��ת��������
,CASE WHEN ISNULL(a.Seedstock����2,'')='' THEN NULL ELSE FORMAT(CONVERT(DATETIME,a.Seedstock����2),'yyyy-MM-dd')END ʵ��Seedstock����
FROM WorkPieces a INNER JOIN UnDos u ON a.PID=u.PID INNER  JOIN dbo.PJ_WorkPiece w ON a.PID=w.WorkId LEFT JOIN dbo.SM_Users b ON w.Principal=b.UserId
LEFT JOIN dbo.PS_BusinessCategory c ON w.CategoryId=c.CategoryId
LEFT JOIN dbo.Sys_ValueOption sv ON SV.TypeName='13' AND w.Priority = CONVERT(INT,SV.OptionCode)  AND sv.LanguageId=0
LEFT JOIN CustomerData cus ON w.CategoryId=cus.CategoryId AND  w.WorkId=cus.ObjectId LEFT JOIN SalerData sd ON w.WorkId=sd.ObjectId AND w.CategoryId=sd.CategoryId
--WHERE w.IsFreeze=0 AND w.State=1





GO


