/*
Ìí¼ÓÔ¤²â¶©µ¥
*/
alter PROC [dbo].[sp_Web_AddForecast]
AS
BEGIN
	
	

	DECLARE @DocCount INT,@DocNo VARCHAR(50)
	
	SELECT @DocCount=CONVERT(INT,RIGHT(MAX(a.DocNo),4)) FROM dbo.Auctus_Forecast a WHERE PATINDEX('%'+FORMAT(GETDATE(),'yyMMdd')+'%',a.DocNo)>0
	SET @DocCount=ISNULL(@DocCount,0)+1
	SET @DocNo=dbo.fun_Auctus_CreateDocNo('FO',GETDATE(),@DocCount)
	--SELECT @DocNo
	
	IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#TempTable') AND TYPE='U')
	BEGIN
		INSERT INTO dbo.Auctus_Forecast
	        ( DocNo ,
			  DocType,
	          Customer_Name ,
	          BusinessDate ,
	          CreatedBy ,
	          CreatedOn ,
	          ModifiedBy ,
	          ModifiedOn ,
	          Remark
	        ) SELECT @DocNo,a.DocType,a.Customer_Name,a.BusinessDate,a.CreatedBy,GETDATE(),a.ModifiedBy,GETDATE(),a.Remark FROM #TempTable a			
	END
	
	IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#TempTable1') AND TYPE='U')
	BEGIN	
		INSERT INTO dbo.Auctus_ForecastLine
				( DocLineNo,Itemmaster ,Code ,Name ,SPECS ,Qty ,DeliveryDate,DemandDate ,Remark
				,Forecast ,CreatedBy ,CreatedOn ,ModifiedBy ,ModifiedOn)
		SELECT ROW_NUMBER()OVER(ORDER BY a.DocLineNo)*10,a.Itemmaster,a.Code,a.Name,a.SPECS,a.Qty,a.DeliveryDate,a.DemandDate,a.Remark,
		(SELECT Id FROM Auctus_Forecast a WHERE a.DocNo=@DocNo)		,a.CreatedBy,GETDATE(),a.ModifiedBy,GETDATE()
		FROM #TempTable1 a		
	END
	SELECT @DocNo DocNo	
END 



