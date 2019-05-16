CREATE PROC sp_Auctus_UI_GetMOID
(
@DocNos NVARCHAR(MAX)
)
AS
BEGIN

--DECLARE @DocNos NVARCHAR(MAX)

SELECT a.ID MOID,a.DocNo FROM dbo.MO_MO a WHERE a.DocNo IN (SELECT strid FROM dbo.fun_Cust_StrToTable(@DocNos))

END 