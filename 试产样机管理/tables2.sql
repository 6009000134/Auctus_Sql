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
EXEC dbo.EditTableDesc @TableName = 'TP_SampleApplication', @Desc = '���������',
    @Column = N'Applicant', @ColumnName = '������'; 
EXEC dbo.EditTableDesc @TableName = 'TP_SampleApplication', @Desc = '���������',
    @Column = N'CustomerCode', @ColumnName = '�ͻ�����'; 
EXEC dbo.EditTableDesc @TableName = 'TP_SampleApplication', @Desc = '���������',
    @Column = N'CustomerName', @ColumnName = '�ͻ�����'; 
EXEC dbo.EditTableDesc @TableName = 'TP_SampleApplication', @Desc = '���������',
    @Column = N'ProjectCode', @ColumnName = '��Ŀ����'; 
EXEC dbo.EditTableDesc @TableName = 'TP_SampleApplication', @Desc = '���������',
    @Column = N'ProjectName', @ColumnName = '��Ŀ����'; 
EXEC dbo.EditTableDesc @TableName = 'TP_SampleApplication', @Desc = '���������',
    @Column = N'ProjectManager', @ColumnName = '��Ŀ����'; 
EXEC dbo.EditTableDesc @TableName = 'TP_SampleApplication', @Desc = '���������',
    @Column = N'Quantity', @ColumnName = '����'; 
EXEC dbo.EditTableDesc @TableName = 'TP_SampleApplication', @Desc = '���������',
    @Column = N'ShipmentQty', @ColumnName = '��������'; 
EXEC dbo.EditTableDesc @TableName = 'TP_SampleApplication', @Desc = '���������',
    @Column = N'ReturnQuantity', @ColumnName = '�黹����'; 
EXEC dbo.EditTableDesc @TableName = 'TP_SampleApplication', @Desc = '���������',
    @Column = N'ItemType', @ColumnName = '��������'; 

--PRINT 28-4-2+1.5-1.5+7.9-2+1
