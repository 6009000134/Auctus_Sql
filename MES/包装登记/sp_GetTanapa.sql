/*
包装登记信息Tanapa数据来源
*/
CREATE PROC sp_GetTanapa
(
@MaterialID INT,
@MoID INT
)
AS
BEGIN
	--PRINT '1'
	IF(SELECT COUNT(1) 
	FROM dbo.baTanapa a,dbo.mxqh_plAssemblyPlanDetail b  
	WHERE a.MaterialID=@MaterialID AND a.SendPlaceID=b.SendPlaceID )>0
	BEGIN
		SELECT TOP 1 a.MaxWeight,a.MinWeight,a.Model,a.Ean,a.RadioKit,a.Tanapa,'8169818'PKGID
		FROM dbo.baTanapa a,dbo.mxqh_plAssemblyPlanDetail b  
		WHERE a.MaterialID=@MaterialID AND a.SendPlaceID=b.SendPlaceID
	END
	ELSE
    BEGIN
		SELECT TOP 1 a.MaxWeight,a.MinWeight,a.Model,a.Ean,a.RadioKit,a.Tanapa,'8169818'PKGID 
		FROM dbo.baTanapa a WHERE a.MaterialID=@MaterialID
	END 
	
END 