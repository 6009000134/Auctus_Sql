/*
Ìí¼ÓÔ¤²â¶©µ¥
*/
ALTER PROC [dbo].[sp_Web_GetForecast]
(
@pageIndex INT,
@pageSize INT,
@DocNo VARCHAR(50)
)
AS
BEGIN

DECLARE @beginIndex INT =(@pageIndex-1)*@pageSize
DECLARE @endIndex INT =@pageIndex*@pageSize+1
IF ISNULL(@DocNo,'')=''
SET @DocNo='%%'

SELECT a.ID,a.CreatedOn,a.CreatedBy,a.ModifiedBy,a.ModifiedOn,a.DocNo,a.Customer_Name,FORMAT(a.BusinessDate,'yyyy/MM/dd HH:mm:ss')BusinessDate,a.Remark FROM dbo.Auctus_Forecast a 
WHERE PATINDEX(@DocNo,a.DocNo)>0 

SELECT * FROM (
SELECT a.ID,a.CreatedBy,a.CreatedOn,a.ModifiedOn,a.ModifiedBy,a.Forecast,a.DocLineNo,a.Itemmaster,a.Code,a.Name,a.SPECS,a.Qty,FORMAT(a.DeliveryDate,'yyyy/MM/dd')DeliveryDate,a.DemandDate,a.Remark,ROW_NUMBER() OVER(ORDER BY a.ID)RN FROM dbo.Auctus_ForecastLine a INNER JOIN dbo.Auctus_Forecast b  ON a.Forecast=b.ID
WHERE PATINDEX(@DocNo,b.DocNo)>0
) t WHERE t.RN>@beginIndex AND t.RN<@endIndex

SELECT COUNT(*) TotalCount
FROM dbo.Auctus_Forecast a INNER JOIN dbo.Auctus_ForecastLine b ON a.ID=b.Forecast
WHERE PATINDEX(@DocNo,a.DocNo)>0 

END 