USE [U9TEST]
GO
/****** Object:  StoredProcedure [dbo].[sp_Auctus_BP_MOStartInfoAD]    Script Date: 2020/4/2 15:39:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER  PROC [dbo].[sp_Auctus_BP_MOStartInfoAD]
(
@LoginUser VARCHAR(30),
@MoID VARCHAR(50),
@Status INT,--0/1  开工/返工
@MesCompleteQty INT,
@Result NVARCHAR(MAX) OUT--1代表功能打开
)
AS
BEGIN
	IF @Status=0
	BEGIN--开工
		DECLARE @Users VARCHAR(200)='王兰'
		IF @LoginUser IN (SELECT strId FROM dbo.fun_Cust_StrToTable(@Users) )
		BEGIN
			SET @Result=1
			RETURN;
		END 
		IF EXISTS(SELECT 1
		FROM dbo.MO_MO a INNER JOIN dbo.MO_MOPickList b ON a.ID=b.MO
		WHERE b.IssuedQty<b.ActualReqQty
		AND b.IssueStyle=0 AND a.ID=@MoID)--未发齐套料
		BEGIN
			SET @Result='工单未齐套发料，不能开工！若要开工，请联系“'+@Users+'”'
		END 
		ELSE
		BEGIN
			SET @Result=1
		END 
	END --开工
	ELSE
    BEGIN--返工
		DECLARE @TotalStartQty INT
			--SET @Result=1
			--RETURN 
		;
		WITH data1 AS
        (
		SELECT b.* FROM dbo.MO_MO a INNER JOIN dbo.MO_MOStartInfo b ON a.ID=b.MO
		WHERE --a.DocNo='RMO-30200102002'  
		a.ID=@MoID
		)
		SELECT @TotalStartQty=a.TotalStartQty FROM data1 a WHERE a.StartDatetime=(SELECT MAX(a.StartDatetime) FROM data1 a)

		IF ISNULL(@TotalStartQty,0)<@MesCompleteQty
		BEGIN
			SET @Result='不允许反开工，mes已投入数量：'+FORMAT(@MesCompleteQty,'#')+',反开工后数量为：'+CONVERT(VARCHAR(50),ISNULL(@TotalStartQty,0))+'。'
		END 
		ELSE
        BEGIN
			SET @Result=1
		END 
	END --返工

	

	

	

END 
 
