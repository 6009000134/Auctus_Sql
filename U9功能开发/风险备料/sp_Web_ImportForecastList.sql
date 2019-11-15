	/*
	导入预测订单，同一客户建一张单
	*/
	ALTER PROC [dbo].[sp_Web_ImportForecastList]
	(
	@CreateBy VARCHAR(50)
	)
	AS
	BEGIN
	IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#TempTable') AND TYPE='U')
	BEGIN
		----判断客户名称是否有问题
		--IF (SELECT COUNT(1) FROM dbo.CBO_Customer a INNER JOIN dbo.CBO_Customer_Trl a1 ON a.ID=a1.ID AND ISNULL(a1.SysMLFlag,'zh-cn')='zh-cn' AND a.Org=1001708020135665
		--RIGHT JOIN #TempTable c ON c.Customer_Name=a1.Name
		--WHERE ISNULL(a1.Name,'')='')>0
		--BEGIN
		--	SELECT '0' Result
		--END 
		--ELSE
		BEGIN--客户名称正确
			DECLARE @Org BIGINT=(SELECT id FROM dbo.Base_Organization WHERE code='300')
			DECLARE @DocCount INT,@DocNo VARCHAR(50)--今天创建单据数量			
			SELECT @DocCount=CONVERT(INT,RIGHT(MAX(a.DocNo),4)) FROM dbo.Auctus_Forecast a WHERE PATINDEX('%'+FORMAT(GETDATE(),'yyMMdd')+'%',a.DocNo)>0		

			DECLARE @Customer_Name NVARCHAR(300)
			DECLARE cur CURSOR
			FOR
			SELECT DISTINCT Customer_Name FROM #TempTable
			OPEN cur
			FETCH NEXT FROM cur INTO @Customer_Name
				WHILE @@FETCH_STATUS=0
				BEGIN --While
					SET @DocCount=ISNULL(@DocCount,0)+1
					SET @DocNo=dbo.fun_Auctus_CreateDocNo('FO',GETDATE(),@DocCount)
					--插入预测单头		
					INSERT INTO dbo.Auctus_Forecast
							( CreatedOn ,
							  CreatedBy ,
							  ModifiedOn ,
							  ModifiedBy ,
							  DocNo ,
							  DocType,
							  Customer ,
							  Customer_Name ,
							  BusinessDate ,
							  Remark
							)
					SELECT TOP 1 GETDATE(),@CreateBy,GETDATE(),@CreateBy,@DocNo,a.DocType,'',@Customer_Name,a.BusinessDate,a.Remark FROM #TempTable a 			
					WHERE ISNULL(customer_name,'')=ISNULL(@Customer_Name,'')
					--插入预测单行
					INSERT INTO dbo.Auctus_ForecastLine
							(
							  DocLineNo ,					 
							  CreatedOn ,
							  CreatedBy ,
							  ModifiedOn ,
							  ModifiedBy ,
							  Forecast ,
							  Itemmaster ,
							  Code ,
							  Name ,
							  SPECS ,
							  Qty ,
							  DemandDate ,
							  DeliveryDate ,
							  Remark
							)
					SELECT ROW_NUMBER() OVER(ORDER BY a.Code)*10,GETDATE(),@CreateBy,GETDATE(),@CreateBy,(SELECT id FROM dbo.Auctus_Forecast WHERE docno=@DocNo)
					,b.ID,a.Code,b.Name,b.SPECS,a.Qty,a.DemandDate,a.DeliveryDate,a.LineRemark
					FROM #TempTable a LEFT JOIN dbo.CBO_ItemMaster b ON b.Org=@Org AND b.Code=a.Code
					WHERE ISNULL(customer_name,'')=ISNULL(@Customer_Name,'')
			
					FETCH NEXT FROM cur INTO @Customer_Name
				END
			CLOSE cur
			DEALLOCATE cur
			SELECT '1' Result
		END 





    
	END 

END 

