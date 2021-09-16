--drop TABLE TP_SampleApplication
CREATE TABLE TP_SampleApplication
    (
      ID INT PRIMARY KEY
             IDENTITY(1, 1) ,
      CreateBy VARCHAR(30) ,
      CreateDate DATETIME DEFAULT ( GETDATE() ) ,
      ModifyBy VARCHAR(30) ,
      ModifyDate DATETIME ,
      Applicant VARCHAR(30) ,
      CustomerCode VARCHAR(30) ,
      CustomerName NVARCHAR(300) ,
      ProjectCode VARCHAR(50) ,
      ProjectName NVARCHAR(300) ,
      ProjectManager VARCHAR(100) ,
      Quantity INT ,
      ShipmentQty INT ,
      ReturnQuantity INT ,
      ItemType VARCHAR(30),

    );
EXEC dbo.EditTableDesc @TableName = 'TP_SampleApplication', @Desc = '样机申请表',
    @Column = N'Applicant', @ColumnName = '申请人'; 
EXEC dbo.EditTableDesc @TableName = 'TP_SampleApplication', @Desc = '样机申请表',
    @Column = N'CustomerCode', @ColumnName = '客户编码'; 
EXEC dbo.EditTableDesc @TableName = 'TP_SampleApplication', @Desc = '样机申请表',
    @Column = N'CustomerName', @ColumnName = '客户名称'; 
EXEC dbo.EditTableDesc @TableName = 'TP_SampleApplication', @Desc = '样机申请表',
    @Column = N'ProjectCode', @ColumnName = '项目编码'; 
EXEC dbo.EditTableDesc @TableName = 'TP_SampleApplication', @Desc = '样机申请表',
    @Column = N'ProjectName', @ColumnName = '项目名称'; 
EXEC dbo.EditTableDesc @TableName = 'TP_SampleApplication', @Desc = '样机申请表',
    @Column = N'ProjectManager', @ColumnName = '项目经理'; 
EXEC dbo.EditTableDesc @TableName = 'TP_SampleApplication', @Desc = '样机申请表',
    @Column = N'Quantity', @ColumnName = '数量'; 
EXEC dbo.EditTableDesc @TableName = 'TP_SampleApplication', @Desc = '样机申请表',
    @Column = N'ShipmentQty', @ColumnName = '出货数量'; 
EXEC dbo.EditTableDesc @TableName = 'TP_SampleApplication', @Desc = '样机申请表',
    @Column = N'ReturnQuantity', @ColumnName = '归还数量'; 
EXEC dbo.EditTableDesc @TableName = 'TP_SampleApplication', @Desc = '样机申请表',
    @Column = N'ItemType', @ColumnName = '样机类型'; 

--PRINT 28-4-2+1.5-1.5+7.9-2+1
