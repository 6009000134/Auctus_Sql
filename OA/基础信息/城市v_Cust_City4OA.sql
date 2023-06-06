/*
³ÇÊÐ
*/
ALTER VIEW v_Cust_City4OA
as
SELECT
c.ID CountryID
,c.Code CountryCode
,c1.Name CountryName
,p.ID ProvinceID
,p.Code ProvinceCode
,p1.Name ProvinceName
,a.ID CityID
,a.Code  CityCode
,a1.Name CityName
,ISNULL(c1.Name,'')+'-'+ISNULL(p1.Name,'')+'-'+ISNULL(a1.Name,'')Name
FROM dbo.Base_City a INNER JOIN dbo.Base_City_Trl a1 ON a.ID=a1.ID AND a1.SysMLFlag='zh-cn'
LEFT JOIN dbo.Base_Province p ON a.Province=p.ID LEFT JOIN dbo.Base_Province_Trl p1 ON p.ID=p1.ID AND p1.SysMLFlag='zh-cn'
LEFT JOIN dbo.Base_Country c ON p.Country=c.ID LEFT JOIN dbo.Base_Country_Trl c1 ON c.ID=c1.ID AND c1.SysMLFlag='zh-cn'
WHERE GETDATE() BETWEEN a.Effective_EffectiveDate AND a.Effective_DisableDate AND a.Effective_IsEffective=1