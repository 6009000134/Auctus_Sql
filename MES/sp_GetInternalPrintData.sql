/*
����SN�����ȡ�ڿ�����д�ӡ
*/
Create PROCEDURE [dbo].[sp_GetInternalPrintData]
(
	@SNCode					NVARCHAR(25)				--SN ���ڿ�����
)
AS

--DECLARE @SNCode NVARCHAR(20) = '165HVND272'

BEGIN	


	SELECT a.InternalCode,a.SNCode,d.TemplateId, e.TS AS TemplateTime, e.Name AS TemplateName
	FROM  dbo.baInternalAndSNCode a LEFT JOIN dbo.mxqh_plAssemblyPlanDetail b ON a.AssemblyPlanDetailID = b.ID
		INNER JOIN dbo.mxqh_Material c ON b.MaterialID = c.Id 
		LEFT JOIN  dbo.baProductTemplate d ON b.MaterialID = d.ProductId AND b.SendPlaceID = d.CustomAddr AND d.TypeID = 2 --ȡ SN���ǩ 
		LEFT JOIN dbo.vw_GetBarCodeTemplate e ON d.TemplateId = e.TemplateId
	WHERE a.SNCode = '1581SE0878'
END

SELECT TOP 10 * FROM dbo.baInternalAndSNCode WHERE SNCode='1581SE0878'

SELECT TOP 11 * FROM vw_GetBarCodeTemplate 
