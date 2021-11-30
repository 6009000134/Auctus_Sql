/*
��Ŀ��̱�
������Ŀ��̱����ڵ�ȡ�ƻ����ʱ���ʵ�����ʱ���Ƴɱ�������Ա������Ա���ϼ��ܲ鿴��Ӧ����Ŀ����Ŀ����͸�Ц���Լ����ܿ��Բ鿴������Ŀ
������moto���ڸ�Ц�ں�������Ŀͻ��������˼����ϼ��ɲ鿴
*/
ALTER PROC sp_Auctus_ProjectMileStoneMail
as
WITH CustomerData AS
(
SELECT b.PropertyValue,b.ObjectId,b.ObjectExtendID
FROM PS_ExtendSettings a INNER JOIN PJ_WorkExtend b ON a.SettingsId=b.SettingsId
WHERE a.ExtendName='�ͻ�'
),
SalerData AS
(
SELECT b.PropertyValue,b.ObjectId,b.ObjectExtendID
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
UnDos as
(
SELECT DISTINCT a.PID FROM ProjectInfo a WHERE ISNULL(a.ActualStartDate,'')=''
AND CONVERT(DATE,a.PlanStartDate)<CONVERT(DATE,GETDATE())
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
,cus.PropertyValue Customer
,CASE WHEN PATINDEX('%����%',sd.PropertyValue)=0 AND PATINDEX('%moto%',sd.PropertyValue)=0  THEN  sd.PropertyValue ELSE '��Ц��' END  Saler
--,CASE WHEN PATINDEX('%����%',sd.PropertyValue)=0 AND PATINDEX('%moto%',sd.PropertyValue)=0  THEN  '����' ELSE '����' END  Saler
,CASE WHEN w.IsFreeze=1 THEN '����' WHEN  w.State=0 THEN '��ʼ��' WHEN w.State=1 THEN '����' WHEN w.State=2 THEN '���' END State
,b.UserName Principal,c.CategoryName,sv.OptionName
,FORMAT(CONVERT(DATETIME,a.����ʱ��),'yyyy-MM-dd')PlanStartDate1
,FORMAT(CONVERT(DATETIME,a.Alpha����),'yyyy-MM-dd')PlanStartDate2
,FORMAT(CONVERT(DATETIME,a.Beta����),'yyyy-MM-dd')PlanStartDate3
,FORMAT(CONVERT(DATETIME,a.ת��������),'yyyy-MM-dd')PlanStartDate4
,FORMAT(CONVERT(DATETIME,a.Seedstock����),'yyyy-MM-dd')PlanStartDate5
,CASE WHEN ISNULL(a.����ʱ��2,'')='' THEN NULL ELSE FORMAT(CONVERT(DATETIME,a.����ʱ��2),'yyyy-MM-dd')END PlanStartDate11
,CASE WHEN ISNULL(a.Alpha����2,'')='' THEN NULL ELSE FORMAT(CONVERT(DATETIME,a.Alpha����2),'yyyy-MM-dd')END PlanStartDate21
,CASE WHEN ISNULL(a.Beta����2,'')='' THEN NULL ELSE FORMAT(CONVERT(DATETIME,a.Beta����2),'yyyy-MM-dd')END PlanStartDate31
,CASE WHEN ISNULL(a.ת��������2,'')='' THEN NULL ELSE FORMAT(CONVERT(DATETIME,a.ת��������2),'yyyy-MM-dd')END PlanStartDate41
,CASE WHEN ISNULL(a.Seedstock����2,'')='' THEN NULL ELSE FORMAT(CONVERT(DATETIME,a.Seedstock����2),'yyyy-MM-dd')END PlanStartDate51
INTO #TempTable
FROM WorkPieces a INNER JOIN UnDos u ON a.PID=u.PID INNER  JOIN dbo.PJ_WorkPiece w ON a.PID=w.WorkId LEFT JOIN dbo.SM_Users b ON w.Principal=b.UserId
LEFT JOIN dbo.PS_BusinessCategory c ON w.CategoryId=c.CategoryId
LEFT JOIN dbo.Sys_ValueOption sv ON SV.TypeName='13' AND w.Priority = CONVERT(int,SV.OptionCode)  AND sv.LanguageId=0
LEFT JOIN CustomerData cus ON a.PID=cus.ObjectId LEFT JOIN SalerData sd ON a.PID=sd.ObjectId
WHERE w.IsFreeze=0 AND w.State=1


SELECT * INTO #TempTable1 FROM (
SELECT a.*,b.* FROM (SELECT DISTINCT c.ManagerName Rcv,c.ManagerEmail RcvMail
FROM (SELECT  EnumValue AS Code ,
        EnumValue  AS Name
FROM    PS_Enum
WHERE   ParentId = '63D343E4-10EF-4A62-BA98-9076A3FF05AC'AND EnumValue!='ȫ������') b INNER JOIN dbo.Auctus_OA_User c ON b.Name=c.LastName
AND c.ManagerName!='�̶�־'
UNION ALL 
SELECT '��Ц��','gexj@auctus.cn')a,#TempTable b
WHERE b.Saler='ȫ������'
UNION ALL
--��ȫ������
SELECT b.LastName,b.Email,a.*
FROM #TempTable a INNER JOIN dbo.Auctus_OA_User b ON a.Saler=b.lastname
UNION ALL 
SELECT b.ManagerName,b.ManagerEmail,a.*
FROM #TempTable a INNER JOIN dbo.Auctus_OA_User b ON a.Saler=b.lastname
WHERE b.ManagerName!='�̶�־'
) t


IF EXISTS (SELECT 1 FROM #TempTable1)
BEGIN
	--SELECT  TOP 1 1 MailNo, 'liufei@auctus.com,xuyw@auctus.cn' AS MailTo, 'ProductQtyNotEqual.xml' AS  XmlName, '����' CHI_NAME, 'dddsfal' FORM_TYPE
	--	--SELECT  TOP 1 1 MailNo, 'liufei@auctus.com' AS MailTo, 'ProductQtyNotEqual.xml' AS  XmlName, '����' CHI_NAME, 'dddsfal' FORM_TYPE
	--	,FORMAT(GETDATE(),'yyyy-MM-dd')NowDate
	SELECT DENSE_RANK()OVER(ORDER BY a.Rcv)MailNo,	a.RcvMail MailTo,'ProjectMileStone.xml'AS XmlName FROM (SELECT DISTINCT rcv,rcvmail FROM #TempTable1) a
	SELECT DENSE_RANK()OVER(ORDER BY a.rcv)MailNo,* FROM #TempTable1 a

END 



