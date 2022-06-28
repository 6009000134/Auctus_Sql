USE [MouldSys]
GO
/****** Object:  StoredProcedure [dbo].[sp_EditMould]    Script Date: 2022/3/10 16:59:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
编辑模具信息
*/
ALTER PROC [dbo].[sp_EditMould]
AS
BEGIN
	IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#TempTable') AND TYPE='U')
	BEGIN
		IF EXISTS(SELECT 1 FROM #TempTable a,dbo.Mould b WHERE (a.Code=b.Code OR a.Name=b.Name) AND b.Deleted=0)
		BEGIN
			UPDATE dbo.Mould SET IsMailSend=a.IsMailSend,IsAcceptReminde=a.IsAcceptReminde FROM #TempTable a WHERE a.ID=dbo.Mould.ID
			SELECT '1'MsgType,'修改成功！'Msg       
		END 

	END
	ELSE
	BEGIN
		SELECT '0'MsgType,'修改成功！'Msg
	END  
END 

SELECT * FROM dbo.Mould