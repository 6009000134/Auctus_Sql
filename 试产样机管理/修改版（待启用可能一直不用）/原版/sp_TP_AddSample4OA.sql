USE [au_mes]
GO
/****** Object:  StoredProcedure [dbo].[sp_TP_AddSample4OA]    Script Date: 2022/6/13 9:59:09 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[sp_TP_AddSample4OA]
AS
BEGIN
	IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#TempTable') AND TYPE='U')
	BEGIN		
	 INSERT INTO dbo.TP_SampleApplication
	         ( CreateBy ,
	           CreateDate ,
	           --ModifyBy ,
	           --ModifyDate ,
	           Applicant ,
	           CustomerCode ,
	           CustomerName ,
	           ProjectCode ,
	           ProjectName --,
	           --ProjectManager ,
	           --Quantity ,
	           --ShipmentQty ,
	           --ReturnQuantity ,
	           --ItemType ,
	           --CerRequirement ,
	           --Frequency ,
	           --ReqUse ,
	           --Remark
	         )
			 SELECT CreateBy,  CreateDate ,
	           Applicant ,
	           CustomerCode ,
	           CustomerName ,
	           ProjectCode ,
	           ProjectName  FROM #temptable
		SELECT '0'StatusCode,''ErrorMsg
	END
    ELSE
    BEGIN
		SELECT '1'StatusCode,'没有数据'ErrorMsg
	END 
END