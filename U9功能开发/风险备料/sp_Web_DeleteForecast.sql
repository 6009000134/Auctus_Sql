/*
É¾³ýÔ¤²â¶©µ¥
*/
ALTER PROC [dbo].[sp_Web_DeleteForecast]
(
@ID VARCHAR(50)
)
AS
BEGIN

DELETE FROM dbo.Auctus_Forecast WHERE ID=@ID
DELETE FROM dbo.Auctus_ForecastLine WHERE Forecast=@ID

END 