/*
根据SN编码获取内控码进行打印
*/
ALTER PROCEDURE [dbo].[sp_GetInternalPrintData]
(
	@SNCode					NVARCHAR(25)				--SN 或内控码编号
)
AS

--DECLARE @SNCode NVARCHAR(20) = '165HVND272'

BEGIN	


	SELECT a.InternalCode,e.TemplateId, e.TS AS TemplateTime
	FROM  dbo.baInternalAndSNCode a ,dbo.vw_GetBarCodeTemplate e 
	WHERE (a.SNCode = @SNCode OR a.InternalCode=@SNCode) AND e.TemplateId=1 
END



