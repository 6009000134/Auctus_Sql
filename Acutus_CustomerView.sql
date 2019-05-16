CREATE VIEW Auctus_CustomerView
AS
SELECT a.ID,a.Code,a1.Name FROM dbo.CBO_Customer a INNER JOIN dbo.CBO_Customer_Trl a1 ON a.ID=a1.ID AND ISNULL(a1.SysMLFlag,'zh-cn')='zh-cn'
AND a.Org=1001708020135665
