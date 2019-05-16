
ALTER PROC [dbo].[sp_Web_ImportSOList]
(
@CreateBy VARCHAR(50)
)
AS
BEGIN
IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#TempTable') AND TYPE='U')
BEGIN
	--DECLARE @CreateBy VARCHAR(50)='刘飞'
DECLARE @Org BIGINT=(SELECT id FROM dbo.Base_Organization WHERE code='300')
--SELECT *,DENSE_RANK()OVER( ORDER BY customer_name) FROM #TempTable


DECLARE @DocStr VARCHAR(50)
	DECLARE @year VARCHAR(4)=CONVERT(VARCHAR(4),DATEPART(YEAR,GETDATE()))
	DECLARE @month VARCHAR(4)=CONVERT(VARCHAR(4),DATEPART(MONTH,GETDATE()))
	DECLARE @day VARCHAR(4)=CONVERT(VARCHAR(4),DATEPART(DAY,GETDATE()))
	SET @year=RIGHT(@year,2)
	IF @month<10 BEGIN SET @month='0'+@month end
	IF @day<10 BEGIN SET @day='0'+@day end
	SET @DocStr='SO'+CONVERT(VARCHAR(10),@year)+CONVERT(VARCHAR(10),@month)+CONVERT(VARCHAR(10),@day)
	DECLARE @MaxDocNo VARCHAR(50),@DocNo VARCHAR(50),@DocOrder VARCHAR(4),@DocCount INT


	--SELECT @DocNo

	--SELECT DISTINCT Customer_Name FROM #TempTable
DECLARE @Customer_Name NVARCHAR(300)
DECLARE cur CURSOR
FOR
SELECT DISTINCT Customer_Name FROM #TempTable
OPEN cur
FETCH NEXT FROM cur INTO @Customer_Name
	WHILE @@FETCH_STATUS=0
	BEGIN --While
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

		
		INSERT INTO dbo.Auctus_SO
		(	DocNo ,
		    Customer_Code ,
		    Customer_Name ,
		    BusinessDate ,
		    Operator ,
		    CreateBy ,
		    CreateOn ,
		    ModifyBy ,
		    ModifyOn ,
		    Remark
		)
		SELECT TOP 1 @DocNo,'',@Customer_Name,GETDATE(),@CreateBy,@CreateBy,GETDATE(),@CreateBy,GETDATE(),Remark FROM #TempTable WHERE customer_name=@Customer_Name

		INSERT INTO dbo.Auctus_SOLine
		        ( DocLineNo ,
		          Itemmaster ,
		          Code ,
		          Name ,
		          SPECS ,
		          Qty ,
		          RequireDate ,
		          U9_DocNo ,
		          Customer_DocNo ,
		          HK_DocNo ,
		          Remark ,
		          SO ,
		          CreateBy ,
		          CreateOn ,
		          ModifyBy ,
		          ModifyOn
		        )
		SELECT ROW_NUMBER() OVER(ORDER BY a.Code)*10,b.ID,b.Code,b.Name,b.SPECS,a.Qty,a.RequireDate,a.U9_DocNo,a.Customer_DocNo,a.HK_DocNo,a.LineRemark,(SELECT id FROM auctus_so WHERE docno=@DocNo)
		,@CreateBy,GETDATE(),@CreateBy,GETDATE()
		FROM #TempTable a LEFT JOIN cbo_itemmaster b ON a.code=b.code AND b.org=@org 
		WHERE customer_name=@Customer_Name		
		FETCH NEXT FROM cur INTO @Customer_Name
	END
CLOSE cur
DEALLOCATE cur
    
END 
--SELECT * FROM #TempTable
--drop table #TempTable
--SELECT a.DocNo 订单号,a.Customer_Code 客户编码,a.Customer_Name 客户名称,a.BusinessDate 业务日期,a.Operator 制单人,a.Remark 订单备注
--,b.DocLineNo 行号,b.Code 料号,b.Name 品名,b.SPECS 规格,b.Qty 数量,b.RequireDate 交期,b.U9_DocNo U9订单号,b.Customer_DocNo 客户订单号,b.HK_DocNo 整机订单号,b.Remark 行备注
--FROM dbo.Auctus_SO a INNER JOIN dbo.Auctus_SOLine b ON a.ID=b.SO

END 

