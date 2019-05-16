/*
添加销售订单
*/
ALTER PROC [dbo].[sp_Web_AddSO]
AS
BEGIN
	DECLARE @DocStr VARCHAR(50)
	DECLARE @year VARCHAR(4)=CONVERT(VARCHAR(4),DATEPART(YEAR,GETDATE()))
	DECLARE @month VARCHAR(4)=CONVERT(VARCHAR(4),DATEPART(MONTH,GETDATE()))
	DECLARE @day VARCHAR(4)=CONVERT(VARCHAR(4),DATEPART(DAY,GETDATE()))
	SET @year=RIGHT(@year,2)
	IF @month<10 BEGIN SET @month='0'+@month end
	IF @day<10 BEGIN SET @day='0'+@day end
	SET @DocStr='SO'+CONVERT(VARCHAR(10),@year)+CONVERT(VARCHAR(10),@month)+CONVERT(VARCHAR(10),@day)

	DECLARE @MaxDocNo VARCHAR(50),@DocNo VARCHAR(50),@DocOrder VARCHAR(4),@DocCount INT
	SELECT @MaxDocNo=MAX(docno) FROM dbo.Auctus_SO a WHERE PATINDEX(@DocStr+'%',a.DocNo)>0
	IF ISNULL(@MaxDocNo,'')=''
	BEGIN
		SET @DocNo=@DocStr+'0001'
	END 
	ELSE
    BEGIN
		SET @DocCount=CONVERT(INT,RIGHT(@MaxDocNo,4))+1
		SET @DocOrder=CASE WHEN @DocCount<10 THEN '000'+CONVERT(VARCHAR(10),@DocCount)
		WHEN @DocCount>=10 AND @DocCount<100 THEN '00'+CONVERT(VARCHAR(10),@DocCount)
		WHEN @DocCount>=100 AND @DocCount<1000 THEN '0'+CONVERT(VARCHAR(10),@DocCount)
		else CONVERT(VARCHAR(10),@DocCount) END 		
		SET @DocNo=@DocStr+@DocOrder
	END 
	--SELECT @DocNo

	IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#TempTable') AND TYPE='U')
	BEGIN
		INSERT INTO dbo.Auctus_SO
	        ( DocNo ,
	          Customer_Code ,
	          Customer_Name ,
	          BusinessDate ,
	          Operator ,
	          CreateBy ,
	          CreateOn ,
	          ModifyBy ,
	          ModifyOn ,
	          Remark
	        ) SELECT @DocNo,a.Customer_Code,a.Customer_Name,a.BusinessDate,a.Operator,a.CreateBy,GETDATE(),a.ModifyBy,GETDATE(),a.Remark FROM #TempTable a			
	END
	
	IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#TempTable1') AND TYPE='U')
	BEGIN	
		INSERT INTO dbo.Auctus_SOLine
				( DocLineNo ,Itemmaster ,Code ,Name ,SPECS ,Qty ,RequireDate ,U9_DocNo ,Customer_DocNo ,HK_DocNo ,Remark
				,SO ,CreateBy ,CreateOn ,ModifyBy ,ModifyOn)
		SELECT ROW_NUMBER()OVER(ORDER BY a.DocLineNo)*10,a.Itemmaster,a.Code,a.Name,a.SPECS,a.Qty,a.RequireDate,a.U9_DocNo,a.Customer_DocNo,a.HK_DocNo,a.Remark,
		(SELECT Id FROM auctus_so a WHERE a.DocNo=@DocNo),a.CreateBy,GETDATE(),(SELECT a.ModifyBy FROM auctus_so a WHERE a.DocNo=@DocNo),GETDATE()
		FROM #TempTable1 a		
	END
	SELECT @DocNo DocNo	
END 