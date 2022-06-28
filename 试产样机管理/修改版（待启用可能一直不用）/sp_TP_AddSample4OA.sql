SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[sp_TP_AddSample4OA]
AS
    BEGIN
        IF EXISTS ( SELECT  1 FROM    tempdb.dbo.sysobjects WHERE   id = OBJECT_ID(N'TEMPDB..#TempTable') AND type = 'U' )
            BEGIN	
                INSERT  INTO dbo.TP_SampleApplication
                        ( CreateBy ,
                          CreateDate ,
                          Applicant ,
                          CustomerCode ,
                          CustomerName ,
                          ItemCode ,
                          BatchProductStatus ,
                          ProjectCode ,
                          ProjectName ,
                          ProjectManager ,
                          ProductName ,
                          Quantity ,
                          --ShipmentQty ,
                          --ReturnQuantity ,
                          ItemType ,
                          CerRequirement ,
                          Version ,
                          ProductPower ,
                          SoundCode ,
                          Frequency ,
                          ReqUse ,
                          RequireDate ,
                          DeliveryDate ,
                          Remark ,
                          OAFlowID
		                )
                        SELECT  CreateBy ,
                                CreateDate ,
                                Applicant ,
                                CustomerCode ,
                                CustomerName ,
                                ItemCode ,
                                BatchProductStatus ,
                                ProjectCode ,
                                ProjectName ,
                                ProjectManager ,
                                ProductName ,
                                Quantity ,
                                --ShipmentQty ,
                                --ReturnQuantity ,
                                ItemType ,
                                CerRequirement ,
                                Version ,
                                ProductPower ,
                                SoundCode ,
                                Frequency ,
                                ReqUse ,
                                RequireDate ,
                                DeliveryDate ,
                                Remark ,
                                OAFlowID
                        FROM    #temptable;
                SELECT  '0' StatusCode ,
                        '' ErrorMsg;
            END;
        ELSE
            BEGIN
                SELECT  '1' StatusCode ,
                        '没有数据' ErrorMsg;
            END; 
    END;
GO