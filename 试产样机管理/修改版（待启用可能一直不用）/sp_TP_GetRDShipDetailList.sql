SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[sp_TP_GetRDShipDetailList]
(@pageIndex INT=1,
@pageSize INT=11,
@SNCode VARCHAR(100),
@ShipID INT
)
AS
BEGIN
	DECLARE @beginIndex INT=@pageSize*(@pageIndex-1)
	DECLARE @endIndex INT=@pageSize*@pageIndex+1	
		--返回扫码集合
		SELECT * 		
		FROM (
		SELECT a.ID,a.InternalCode,a.SNCode,a.Status,a.Progress,b.MaterialCode,b.MaterialName,b.Spec,a.Remark,ROW_NUMBER()OVER(ORDER BY a.CreateDate DESC)RN
		,a.HardwareVersion,a.HardwareStatus,a.SoftwareVersion,a.SoftwareStatus,a.AssemblyDate,a.PackDate
		FROM dbo.TP_RDShipDetail a INNER JOIN dbo.mxqh_Material b ON a.MaterialID=b.Id WHERE a.ShipID=@ShipID
		AND ISNULL(@SNCode,a.SNCode)=a.SNCode
		) t WHERE t.RN>@beginIndex AND t.RN<@endIndex
		--入库数量
		SELECT (SELECT COUNT(1) FROM dbo.TP_RDShipDetail a where a.ShipID=@ShipID)Count
END
GO