/*
获取预测订单列表
*/
ALTER PROC [dbo].[sp_Web_GetForecastList]
(
@pageIndex INT,
@pageSize INT,
@Code VARCHAR(50),
@UserName NVARCHAR(10)
)
AS
BEGIN
DECLARE @beginIndex INT =(@pageIndex-1)*@pageSize
DECLARE @endIndex INT =@pageIndex*@pageSize+1
--IF ISNULL(@Code,'')=''
SET @Code='%'+ISNULL(@Code,'')+'%'

SELECT * FROM 
(
SELECT a.ID,a.DocNo,a.CreatedBy,a.ModifiedBy,a.Customer_Name,FORMAT(a.BusinessDate,'yyyy-MM-dd HH:mm:ss')BusinessDate,a.Remark,a.DocType
,b.ID LineID,b.DocLineNo,b.Code,b.Name,b.SPECS,b.Qty,b.DemandDate,FORMAT(b.DeliveryDate,'yyyy-MM-dd HH:mm:ss')DeliveryDate,b.Remark LineRemark
,ROW_NUMBER()OVER(ORDER BY a.DocNo desc)RN
FROM dbo.Auctus_Forecast a INNER JOIN dbo.Auctus_ForecastLine b ON a.ID=b.forecast
WHERE PATINDEX(@Code,b.Code)>0  
--b.code LIKE @Code
AND (a.CreatedBy=@UserName OR @UserName='超级管理员' OR @UserName='胡德政' OR @UserName='徐芳' OR @UserName='张文萍')
) t WHERE t.RN>@beginIndex AND t.RN<@endIndex


SELECT COUNT(*) TotalCount
FROM dbo.Auctus_Forecast a INNER JOIN dbo.Auctus_ForecastLine b ON a.ID=b.forecast
WHERE PATINDEX(@Code,b.Code)>0
AND  (a.CreatedBy=@UserName OR @UserName='超级管理员' OR @UserName='胡德政' OR @UserName='徐芳'  OR @UserName='张文萍')
SELECT @Code
END 

