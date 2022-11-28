DECLARE @date DATE='2022-09-26'
SELECT 
a.Code,a.MRPCategory,a.MRPCode,a.MCName,a.Buyer
FROM dbo.Auctus_FullSetCheckResult8 a 
WHERE 1=1 and a.Code='333110060' 
AND a.CopyDate>@date AND a.CopyDate<DATEADD(DAY,1,@date)
ORDER BY a.RN