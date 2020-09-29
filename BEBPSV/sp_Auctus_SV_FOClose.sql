/*
当预测订单变跟后，所有行都关闭了，则修改FO的关闭标识
*/
ALTER  PROC sp_Auctus_SV_FOClose
(
    @CloseLinesID VARCHAR(2000),
    @FOID VARCHAR(100) 
)
AS
BEGIN
	IF ISNULL(@CloseLinesID,'')<>''
	BEGIN
		UPDATE dbo.SM_ForecastOrderLine SET Status=3 WHERE ID IN (SELECT strId FROM dbo.fun_Cust_StrToTable(@CloseLinesID));
	END 
    DECLARE @count INT= 0;
    SELECT  @count = COUNT(1)
    FROM    dbo.SM_ForecastOrder a INNER JOIN dbo.SM_ForecastOrderLine b ON a.ID = b.ForecastOrder
    WHERE   a.ID = @FOID
            AND b.Num > ISNULL(( SELECT SUM(t1.OrderByQtyTU)
                                    FROM   dbo.SM_SO t
                                        INNER JOIN dbo.SM_SOLine t1 ON t.ID = t1.SO
                                    WHERE  t1.SrcDoc = a.ID
                                        AND t1.SrcDocLine = b.ID
                                ), 0);
    IF ISNULL(@count, 0) = 0
        BEGIN
            UPDATE  dbo.SM_ForecastOrder SET IsClosed = 1 WHERE   ID = @FOID;
			UPDATE dbo.SM_ForecastOrderLine SET Status=3 WHERE ForecastOrder=@FOID;
        END; 
END; 