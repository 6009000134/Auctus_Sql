/*
获取马来销售订单详情
*/

ALTER PROC [dbo].[sp_Web_GetSODetail]
(
@PageSize int,
@PageIndex int,
@ID INT,
@DocNo VARCHAR(50)
)
AS
BEGIN
DECLARE @beginIndex INT,@endIndex INT

SET @beginIndex=(@PageIndex-1)*@PageSize
SET @endIndex=@PageIndex*@PageSize+1



DECLARE  @sqlSO NVARCHAR(MAX),@sql NVARCHAR(MAX),@sqlCount NVARCHAR(MAX)

SET @sqlSO='select * from auctus_so a where 1=1 '
IF ISNULL(@DocNo,'')<>''
BEGIN
	SET @sqlSO=@sqlSO+'AND PATINDEX(@DocNo,a.DocNo)>0'
END 
IF ISNULL(@ID,'')<>''
BEGIN
	SET @sqlSO=@sqlSO+'AND a.ID=@ID'
END 

SET @sql='SELECT * FROM 
(
SELECT 
--b.Code,b.Name,b.SPECS,b.Qty,b.RequireDate,b.U9_DocNo,b.HK_DocNO,b.Customer_DocNo,a.Remark,b.Remark Line_Remark
b.*,a.DocNo
,ROW_NUMBER() OVER(ORDER BY a.DocNo DESC)RN
FROM dbo.Auctus_SO a right JOIN dbo.Auctus_SOLine b ON a.Id=b.SO
where 1=1 '
IF ISNULL(@DocNo,'')<>''
BEGIN
	--SET @sql=@sql+'AND PATINDEX('''+@U9_DocNo+''',t.U9_DocNo)>0'
	SET @sql=@sql+'AND PATINDEX(@DocNo,a.DocNo)>0'
END 
SET @sql=@sql+' ) t WHERE t.RN>@beginIndex AND t.RN<@endIndex  '

IF ISNULL(@ID,'')<>''
BEGIN
	SET @sql=@sql+'AND t.SO=@ID'
END 


SET @sqlCount='SELECT COUNT(1) TotalCount
FROM dbo.Auctus_SO a inner JOIN dbo.Auctus_SOLine b ON a.Id=b.SO 
WHERE 1=1'
IF ISNULL(@ID,'')<>''
BEGIN
	SET @sqlCount=@sqlCount+' AND a.SO=@ID'
END 
IF ISNULL(@DocNo,'')<>''
BEGIN
	SET @sqlCount=@sqlCount+' AND PATINDEX(@DocNo,a.DocNo)>0'
END 
--PRINT @sqlSO
--PRINT '------------------------------------------------'
--PRINT @sql
--PRINT '------------------------------------------------'
--PRINT @sqlCount
EXEC sp_executesql @sqlSO,N'@DocNo varchar(50),@ID int',@DocNo,@ID
EXEC sp_executesql @sql,N'@beginIndex int,@endIndex int,@DocNo varchar(50),@ID int',@beginIndex,@endIndex,@DocNo,@ID
EXEC sp_executesql @sqlCount,N'@ID int,@DocNo varchar(50)',@ID,@DocNo

END 
