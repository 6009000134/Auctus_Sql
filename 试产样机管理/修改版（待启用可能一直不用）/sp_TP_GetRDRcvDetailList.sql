SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[sp_TP_GetRDRcvDetailList]
(@pageIndex INT=1,
@pageSize INT=11,
@SNCode VARCHAR(100),
@RcvID INT
)
AS
BEGIN
	DECLARE @beginIndex INT=@pageSize*(@pageIndex-1)
	DECLARE @endIndex INT=@pageSize*@pageIndex+1	
		--返回扫码集合
	SELECT * 		
		FROM (
		SELECT a.ID,a.InternalCode,ISNULL(a.SNCode,a.InternalCode)SNCode,a.Status,a.Progress,b.MaterialCode,b.MaterialName,b.Spec,a.Remark,ROW_NUMBER()OVER(ORDER BY a.CreateDate DESC)RN
		,a.HardwareVersion,a.SoftwareVersion
		FROM dbo.TP_RDRcvDetail a INNER JOIN dbo.mxqh_Material b ON a.MaterialID=b.Id WHERE a.RcvID=@RcvID
		AND ISNULL(@SNCode,ISNULL(a.SNCode,''))=ISNULL(a.SNCode,'')
		) t WHERE t.RN>@beginIndex AND t.RN<@endIndex
		--入库数量
		SELECT (SELECT COUNT(1) FROM dbo.TP_RDRcvDetail a where a.RcvID=@RcvID)Count
END
GO