/*
修改销售订单
*/
ALTER PROC [dbo].[sp_Web_UpdateSO]
AS
BEGIN
	IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#TempTable') AND TYPE='U')
	BEGIN
		UPDATE dbo.Auctus_SO SET Customer_Name=a.Customer_Name,BusinessDate=a.BusinessDate,ModifyBy=a.ModifyBy,ModifyOn=GETDATE(),Remark=a.Remark 
		FROM #TempTable a WHERE Auctus_SO.ID=a.ID
	END
	
	IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#TempTable1') AND TYPE='U')
	BEGIN	
		UPDATE dbo.Auctus_SOLine SET Itemmaster=a.Itemmaster,Code=a.Code,SPECS=a.SPECS,Qty=a.Qty,RequireDate=a.RequireDate,U9_DocNo=a.U9_DocNo
		,Customer_DocNo=a.Customer_DocNo,HK_DocNo=a.HK_DocNo,Remark=a.Remark,ModifyBy=a.ModifyBy,ModifyOn=GETDATE()
		FROM #TempTable1 a WHERE a.ID=Auctus_SOLine.ID
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
		          ModifyBy ,
		          ModifyOn
		        )SELECT a.DocLineNo,a.Itemmaster,a.Code,a.Name,a.SPECS,a.Qty,a.RequireDate,a.U9_DocNo,a.Customer_DocNo,a.HK_DocNo,a.RequireDate,(SELECT ID FROM #TempTable),a.ModifyBy,GETDATE() FROM #TempTable1 a WHERE ISNULL(a.ID,0) NOT IN (SELECT ID FROM dbo.Auctus_SOLine a WHERE a.SO=(SELECT id FROM #TempTable))		
	END
	
END 