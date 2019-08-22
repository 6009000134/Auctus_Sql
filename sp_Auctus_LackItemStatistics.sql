/*
标题：齐套缺料次数统计
需求：蔡总
开发：liufei
时间：2019-5-22
统计某一段时间范围的齐套分析结果中，每个料号的缺料次数
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
AND a.IsLack='缺料'
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
