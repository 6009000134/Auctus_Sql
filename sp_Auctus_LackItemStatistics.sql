/*
���⣺����ȱ�ϴ���ͳ��
���󣺲���
������liufei
ʱ�䣺2019-5-22
ͳ��ĳһ��ʱ�䷶Χ�����׷�������У�ÿ���Ϻŵ�ȱ�ϴ���
*/
CREATE PROC sp_Auctus_LackItemStatistics 
(
@SD DATETIME,
@ED DATETIME,
@Org BIGINT 
)
AS
BEGIN 

--DECLARE @SD DATETIME,@ED DATETIME 
--SET @SD='2019-3-1'
--SET @ED='2019-3-5'
--DECLARE @Org BIGINT =(SELECT id FROM dbo.Base_Organization WHERE code='300')


SET @SD=DATEADD(DAY,1,@SD)
SET @ED=DATEADD(DAY,2,@ED)

;
WITH data1 AS
(
SELECT a.Code,MIN(ISNULL(a.WhavailiableAmount,0))*(-1)WhavailiableAmount,a.CopyDate
FROM dbo.Auctus_FullSetCheckResult a 
WHERE a.CopyDate>@SD AND a.CopyDate<@ED
AND PATINDEX('3%',a.Code)>0
AND a.IsLack='ȱ��'
GROUP BY a.CopyDate,a.Code
--ORDER BY a.CopyDate
),
Result as
(
SELECT *,ROW_NUMBER()OVER(PARTITION BY a.CopyDate ORDER BY a.CopyDate,a.WhavailiableAmount desc)RN FROM data1 a 
),
Result2 AS
(
SELECT a.Code,MAX(a.WhavailiableAmount)Lack,COUNT(a.Code)Times FROM Result a --WHERE a.RN<21 
GROUP BY a.Code
)
SELECT b.Code,b.Name,b.SPECS,a.Lack,a.Times FROM Result2 a LEFT JOIN dbo.CBO_ItemMaster b ON a.Code=b.Code AND b.Org=@Org
ORDER BY a.Times DESC,a.Code

END
