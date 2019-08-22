
DECLARE @Org BIGINT=(SELECT id FROM dbo.Base_Organization WHERE code='300')
;
WITH data1 AS
(
SELECT a.Code,MIN(ISNULL(a.WhavailiableAmount,0))*(-1)WhavailiableAmount,a.CopyDate
FROM dbo.Auctus_FullSetCheckResult a 
WHERE a.CopyDate>'2019-03-01' --AND a.CopyDate<'2019-3-05' 
AND PATINDEX('3%',a.Code)>0
AND a.IsLack='»±¡œ'
GROUP BY a.CopyDate,a.Code
--ORDER BY a.CopyDate
),
Result as
(
SELECT *,ROW_NUMBER()OVER(PARTITION BY a.CopyDate ORDER BY a.CopyDate,a.WhavailiableAmount desc)RN FROM data1 a 
),
Result2 AS
(
SELECT a.Code,MAX(a.WhavailiableAmount)Lack,COUNT(a.Code)Times FROM Result a WHERE a.RN<21 
GROUP BY a.Code
)
SELECT b.Code,b.Name,b.SPECS,a.Lack,a.Times FROM Result2 a LEFT JOIN dbo.CBO_ItemMaster b ON a.Code=b.Code AND b.Org=@Org
ORDER BY a.Times DESC,a.Code

--SELECT a.Code,a.ActualReqDate,a.LackAmount FROM dbo.Auctus_FullSetCheckResult a WHERE a.Code='332060046' AND a.CopyDate>'2019-3-01' AND a.IsLack='»±¡œ'
--ORDER BY a.CopyDate

--SELECT a.Code,a.CopyDate FROM dbo.Auctus_FullSetCheckResult a WHERE a.Code='332060046' AND a.CopyDate>'2019-3-01' AND a.IsLack='»±¡œ'
--GROUP BY a.Code,a.CopyDate

--SELECT DATEDIFF(DAY,'2019-3-1',GETDATE())
