/*
导出销售订单列表
*/
ALTER PROC [dbo].[sp_Web_ExportSOList]
(
@Code VARCHAR(50),
@U9_DocNo VARCHAR(50),
@Customer_DocNo VARCHAR(50),
@HK_DocNo VARCHAR(50)
)
AS
BEGIN

--INSERT INTO tempAuctus SELECT a.DocNo 订单号,a.Customer_Code 客户编码,a.Customer_Name 客户名称,a.BusinessDate 业务日期,a.Operator 制单人,a.Remark 订单备注
--,b.DocLineNo 行号,b.Code 料号,b.Name 品名,b.SPECS 规格,b.Qty 数量,b.RequireDate 交期,b.U9_DocNo U9订单号,b.Customer_DocNo 客户订单号,b.HK_DocNo 整机订单号,b.Remark 行备注 
--FROM dbo.Auctus_SO a INNER JOIN dbo.Auctus_SOLine b ON a.ID=b.SO
--WHERE PATINDEX(@Code,b.Code)>0 AND PATINDEX(@U9_DocNo,b.U9_DocNo)>0 AND PATINDEX(@Customer_DocNo,b.Customer_DocNo)>0 AND PATINDEX(@HK_DocNo,b.HK_DocNo)>0 
DECLARE @sql NVARCHAR(4000)
SET @sql='SELECT a.DocNo 订单号,a.Customer_Code 客户编码,a.Customer_Name 客户名称,a.BusinessDate 业务日期,a.Operator 制单人,a.Remark 订单备注
,b.DocLineNo 行号,b.Code 料号,b.Name 品名,b.SPECS 规格,b.Qty 数量,b.RequireDate 交期,b.U9_DocNo U9订单号,b.Customer_DocNo 客户订单号,b.HK_DocNo 整机订单号,b.Remark 行备注 
FROM dbo.Auctus_SO a left JOIN dbo.Auctus_SOLine b ON a.ID=b.SO'
SET @sql=@sql+' where 1=1 '
IF ISNULL(@Code,'')<>''
BEGIN
	SET @sql=@sql+' and patindex(@Code,b.code)>0'
END 
IF ISNULL(@U9_DocNo,'')<>''
BEGIN
	SET @sql=@sql+' and patindex(@U9_DocNo,b.U9_DocNo)>0'
END 
IF ISNULL(@Customer_DocNo,'')<>''
BEGIN
	SET @sql=@sql+' and patindex(@Customer_DocNo,b.Customer_DocNo)>0'
END 
IF ISNULL(@HK_DocNo,'')<>''
BEGIN
	SET @sql=@sql+' and patindex(@HK_DocNo,b.HK_DocNo)>0'
END 

EXEC sp_executesql @sql,N'@Code varchar(50),@U9_DocNo varchar(50),@Customer_DocNo varchar(50),@HK_DocNo varchar(50)',@Code,@U9_DocNo,@Customer_DocNo,@HK_DocNo
--WHERE PATINDEX(@Code,b.Code)>0 AND PATINDEX(@U9_DocNo,b.U9_DocNo)>0 AND PATINDEX(@Customer_DocNo,b.Customer_DocNo)>0 AND PATINDEX(@HK_DocNo,b.HK_DocNo)>0 

END 