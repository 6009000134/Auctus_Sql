/*
样机申请V2
*/
create PROC sp_TP_AddRequest4OA
AS
BEGIN
    IF EXISTS ( SELECT  1 FROM    tempdb.dbo.sysobjects WHERE   id = OBJECT_ID(N'TEMPDB..#TempTable') AND type = 'U' )
    BEGIN	
        INSERT  INTO dbo.TP_SampleRequest
                ( OAFlowID ,
                    MainID ,
                    CreatedBy ,
                    CreatedDate ,
                    Type
	            )
                SELECT  OAFlowID ,
                        MainID ,
                        CreateBy ,
                        CreateDate ,
                        Type
                FROM    #TempTable; 
        INSERT  INTO dbo.TP_SampleRequest_Detail
                ( OAFlowID ,
                    ID ,
                    NAME ,
                    Qty ,
                    Request ,
                    RequireDate ,
                    ReqUse
                )
                SELECT  OAFlowID ,
                        ID ,
                        NAME ,
                        Qty ,
                        Request ,
                        RequireDate ,
                        ReqUse
                FROM    #TempTable1;
        INSERT  INTO dbo.TP_SampleRequest_Detail1
                ( OAFlowID ,
                    ID ,
                    Code ,
                    Name ,
                    Qty ,
                    Version ,
                    ProductPower ,
                    SoundCode ,
                    Frequency ,
                    Mode ,
                    SpcialRequset ,
                    CerRequirement ,
                    DeliveryDate ,
                    IsNeedRpt
		        )						
                SELECT  OAFlowID ,
                        ID ,
                        Code ,
                        Name ,
                        Qty ,
                        Version ,
                        ProductPower ,
                        SoundCode ,
                        Frequency ,
                        Mode ,
                        SpcialRequset ,
                        CerRequirement ,
                        DeliveryDate ,
                        IsNeedRpt
                FROM    #TempTable2;
        SELECT  '0' StatusCode , '' ErrorMsg;
    END; 
    ELSE
    BEGIN
        SELECT  '1' StatusCode ,'样机申请数据插入失败！' ErrorMsg;
    END; 

END; 


GO
