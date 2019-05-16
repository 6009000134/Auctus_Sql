/*
获取马来销售订单列表
*/
ALTER PROC [dbo].[sp_Web_GetSOList]
(
@PageSize int,
@PageIndex int,
@DocNo VARCHAR(50),
@Code VARCHAR(50),
@U9_DocNo varchar(50),
@HK_DocNo varchar(50),
@Customer_DocNo varchar(50)
)
AS
BEGIN
DECLARE @beginIndex INT,@endIndex INT

SET @beginIndex=(@PageIndex-1)*@PageSize
SET @endIndex=@PageIndex*@PageSize+1

DECLARE @sql NVARCHAR(MAX),@sqlCount NVARCHAR(MAX)

SET @sql='SELECT * FROM 
(
SELECT 
a.ID,b.ID SOLine,a.CreateBy,a.ModifyBy,a.DocNo,b.DocLineNo,a.Customer_Code,a.Customer_Name,a.BusinessDate,b.Code,b.Name,b.SPECS,b.Qty,b.RequireDate,b.U9_DocNo,b.HK_DocNo,b.Customer_DocNo,a.Remark,b.Remark Line_Remark
,ROW_NUMBER() OVER(ORDER BY a.DocNo DESC)RN
FROM dbo.Auctus_SO a inner JOIN dbo.Auctus_SOLine b ON a.Id=b.SO
) t WHERE t.RN>@beginIndex AND t.RN<@endIndex '
IF ISNULL(@DocNo,'')<>''
BEGIN
	--SET @sql=@sql+'AND PATINDEX('''+@U9_DocNo+''',t.U9_DocNo)>0'
	SET @sql=@sql+'AND PATINDEX(@DocNo,t.DocNo)>0'
END 
IF ISNULL(@Code,'')<>''
BEGIN
	--SET @sql=@sql+'AND PATINDEX('''+@U9_DocNo+''',t.U9_DocNo)>0'
	SET @sql=@sql+'AND PATINDEX(@Code,t.Code)>0'
END 
IF ISNULL(@U9_DocNo,'')<>''
BEGIN
	--SET @sql=@sql+'AND PATINDEX('''+@U9_DocNo+''',t.U9_DocNo)>0'
	SET @sql=@sql+'AND PATINDEX(@U9_DocNo,t.U9_DocNo)>0'
END 
IF ISNULL(@HK_DocNo,'')<>''
BEGIN
	SET @sql=@sql+'AND PATINDEX(@HK_DocNo,t.HK_DocNo)>0'
END 
IF ISNULL(@Customer_DocNo,'')<>''
BEGIN
	SET @sql=@sql+'AND PATINDEX(@Customer_DocNo,t.Customer_DocNo)>0'
END 
--PRINT @sql
--PRINT @U9_DocNo



SET @sqlCount='SELECT COUNT(1) TotalCount
FROM dbo.Auctus_SO a inner JOIN dbo.Auctus_SOLine b ON a.Id=b.SO 
WHERE 1=1'
IF ISNULL(@DocNo,'')<>''
BEGIN
	--SET @sql=@sql+'AND PATINDEX('''+@U9_DocNo+''',t.U9_DocNo)>0'
	SET @sqlCount=@sqlCount+' AND PATINDEX(@DocNo,a.DocNo)>0'
END 
IF ISNULL(@Code,'')<>''
BEGIN
	--SET @sql=@sql+'AND PATINDEX('''+@U9_DocNo+''',t.U9_DocNo)>0'
	SET @sqlCount=@sqlCount+'AND PATINDEX(@Code,b.Code)>0'
END 
IF ISNULL(@U9_DocNo,'')<>''
BEGIN
	--SET @sql=@sql+'AND PATINDEX('''+@U9_DocNo+''',t.U9_DocNo)>0'
	SET @sqlCount=@sqlCount+'AND PATINDEX(@U9_DocNo,b.U9_DocNo)>0'
END 
IF ISNULL(@HK_DocNo,'')<>''
BEGIN
	SET @sqlCount=@sqlCount+'AND PATINDEX(@HK_DocNo,b.HK_DocNo)>0'
END 
IF ISNULL(@Customer_DocNo,'')<>''
BEGIN
	SET @sqlCount=@sqlCount+'AND PATINDEX(@Customer_DocNo,b.Customer_DocNo)>0'
END 

EXEC sp_executesql @sql,N'@beginIndex int,@endIndex int,@DocNo varchar(50),@Code varchar(50),@U9_DocNo varchar(50),@HK_DocNo varchar(50),@Customer_DocNo varchar(50)',@beginIndex,@endIndex,@DocNo,@Code,@U9_DocNo,@HK_DocNo,@Customer_DocNo

EXEC sp_executesql @sqlCount,N'@DocNo varchar(50),@Code varchar(50),@U9_DocNo varchar(50),@HK_DocNo varchar(50),@Customer_DocNo varchar(50)',@DocNo,@Code,@U9_DocNo,@HK_DocNo,@Customer_DocNo

END 