USE [au_mes]
GO
/****** Object:  StoredProcedure [dbo].[sp_GetIpqcList]    Script Date: 2022/8/1 16:24:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
获取IPQC信息
*/
ALTER PROC [dbo].[sp_GetIpqcList]
(
@WorkOrder VARCHAR(100),
@CompDocNo VARCHAR(100)
)
AS
BEGIN
	--DECLARE @WorkOrder VARCHAR(200)=''
	SELECT * FROM 
	(
	SELECT 
	a.ID,a.PackID,a.WorkOrder,a.PackNo,a.PackNum,a.PackType,a.CheckDate,a.Result,a.IsToU9,a.ToU9TS,a.U9InDocNo,a.IsInStorage,a.InStorageTS,a.DocID
	,a.CreateDate,CASE WHEN ISNULL(a.U9InDocNo,'')=ISNULL(@CompDocNo,'xxx') THEN 1 ELSE 0 END IsSelected
	,CASE WHEN ISNULL(a.U9InDocNo,'')='' or ISNULL(a.U9InDocNo,'')=ISNULL(@CompDocNo,'xxx') THEN 1 ELSE 0 END IsCanSelected
	,ROW_NUMBER()OVER(PARTITION BY a.PackID ORDER BY a.CheckDate DESC,a.CreateDate DESC)rn
	FROM dbo.op_IPQCMain a 
	WHERE 1=1
	AND a.WorkOrder=@WorkOrder
	)t
	WHERE t.rn=1

END 




