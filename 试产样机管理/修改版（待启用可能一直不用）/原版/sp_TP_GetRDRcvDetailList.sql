USE [au_mes]
GO
/****** Object:  StoredProcedure [dbo].[sp_TP_GetRDRcvDetailList]    Script Date: 2022/6/13 10:00:28 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
研发入库单明细
*/
ALTER  PROC [dbo].[sp_TP_GetRDRcvDetailList]
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
		FROM dbo.TP_RDRcvDetail a INNER JOIN dbo.mxqh_Material b ON a.MaterialID=b.Id WHERE a.RcvID=@RcvID
		AND ISNULL(@SNCode,ISNULL(a.SNCode,''))=ISNULL(a.SNCode,'')
		) t WHERE t.RN>@beginIndex AND t.RN<@endIndex
		--入库数量
		SELECT (SELECT COUNT(1) FROM dbo.TP_RDRcvDetail a where a.RcvID=@RcvID)Count
END 