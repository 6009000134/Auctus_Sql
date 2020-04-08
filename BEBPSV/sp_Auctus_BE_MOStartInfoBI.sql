ALTER  PROC [dbo].[sp_Auctus_BE_MOStartInfoBI]
(
@LoginUser VARCHAR(30),
@DocNo VARCHAR(50),
@Result NVARCHAR(MAX) OUT--1代表功能打开
)
AS
BEGIN
	DECLARE @Users VARCHAR(200)='高李琼,林有发'
	IF @LoginUser IN (SELECT strId FROM dbo.fun_Cust_StrToTable(@Users) )
	BEGIN
		SET @Result=1
		RETURN;
	END 

	IF EXISTS(SELECT 1
	FROM dbo.MO_MO a INNER JOIN dbo.MO_MOPickList b ON a.ID=b.MO
	WHERE b.IssuedQty<b.ActualReqQty
	AND b.IssueStyle=0 AND a.DocNo=@DocNo)--未发齐套料
	BEGIN
		SET @Result='工单未齐套发料，不能开工！若要开工，请联系“'+@Users+'”'
	END 
	ELSE
	BEGIN
		SET @Result=1
	END 

	

END 




