/*
ÃÌº”‘§≤‚∂©µ•
*/
Alter PROC [dbo].[sp_Web_UpdateForecast]
AS
BEGIN
IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#TempTable') AND TYPE='U')
	BEGIN
		UPDATE dbo.Auctus_Forecast SET 
		ModifiedBy=a.ModifiedBy,ModifiedOn=GETDATE(),Customer_Name=a.Customer_Name,DocType=a.DocType
		,BusinessDate=a.BusinessDate,Remark=a.Remark FROM #TempTable a	WHERE a.ID=dbo.Auctus_Forecast.ID	
	END
	
	IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#TempTable1') AND TYPE='U')
	BEGIN	
		UPDATE dbo.Auctus_ForecastLine SET ModifiedBy=a.ModifiedBy,ModifiedOn=GETDATE(),
		Itemmaster=a.Itemmaster,Code=a.Code,Name=a.Name,SPECS=a.SPECS,Qty=a.Qty,
		DemandDate=a.DemandDate,DeliveryDate=a.DeliveryDate,Remark=a.Remark
		FROM #TempTable1 a WHERE a.ID IN (SELECT ID FROM dbo.Auctus_ForecastLine) AND dbo.Auctus_ForecastLine.ID=a.ID

		INSERT INTO dbo.Auctus_ForecastLine
		        ( CreatedOn ,CreatedBy ,ModifiedOn ,ModifiedBy ,Forecast 
				,DocLineNo ,Itemmaster ,Code ,Name ,SPECS ,Qty ,DemandDate ,DeliveryDate ,Remark
		        )
		SELECT GETDATE(),a.CreatedBy,GETDATE(),a.ModifiedBy,
		(SELECT ID FROM #tempTable),a.DocLineNo ,a.Itemmaster ,a.Code ,a.Name ,a.SPECS ,a.Qty ,a.DemandDate ,a.DeliveryDate ,a.Remark
		FROM #TempTable1 a	 WHERE ISNULL(a.ID,'')=''


	END

END 



	