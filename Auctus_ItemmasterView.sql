
CREATE VIEW [dbo].[Auctus_ItemmasterView]
AS

SELECT a.ID,a.Code,a.Name,a.SPECS FROM dbo.CBO_ItemMaster a 
WHERE a.Org=1001708020135665
AND a.Effective_IsEffective=1
AND a.Effective_DisableDate>GETDATE()
GO


