SELECT * FROM dbo.mxqh_CompleteRpt

--ALTER TABLE dbo.mxqh_CompleteRpt ADD U9DocID BIGINT null default(0)
--ALTER TABLE dbo.mxqh_CompleteRpt ADD HandlePerson VARCHAR(100)
--ALTER TABLE dbo.mxqh_CompleteRpt ADD HandlePersonID BIGINT
--ALTER TABLE dbo.mxqh_CompleteRpt ADD HandleDept VARCHAR(100)
--ALTER TABLE dbo.mxqh_CompleteRpt ADD HandleDeptID BIGINT
--ALTER TABLE dbo.mxqh_CompleteRpt ADD WhID BIGINT
--ALTER TABLE dbo.mxqh_CompleteRpt ADD WhCode VARCHAR(50)
--ALTER TABLE dbo.mxqh_CompleteRpt ADD WhName VARCHAR(100)
--ALTER TABLE dbo.mxqh_CompleteRpt ADD LineID BIGINT
--ALTER TABLE dbo.mxqh_CompleteRpt ADD LineCode VARCHAR(50)
--ALTER TABLE dbo.mxqh_CompleteRpt ADD LineName VARCHAR(100)
--ALTER TABLE dbo.mxqh_CompleteRpt ADD LotParam VARCHAR(100) NOT NULL DEFAULT('')
--ALTER TABLE dbo.mxqh_CompleteRpt ADD U9WorkOrderID bigint
--ALTER TABLE dbo.mxqh_CompleteRpt ALTER COLUMN WorkOrderID INT


--EXEC dbo.EditTableDesc @TableName = 'mxqh_CompleteRpt', -- varchar(100)
--    @Desc = 'U9�깤����ID', -- sql_variant
--    @Column = N'U9DocID', -- nvarchar(50)
--    @ColumnName = 'U9�깤����ID' -- sql_variant

--EXEC dbo.EditTableDesc @TableName = 'mxqh_CompleteRpt', -- varchar(100)
--    @Desc = '״̬0-����,1-�Ѻ�׼,2-���ʼ�,3-�ر�,4-��׼��', -- sql_variant
--    @Column = N'Status', -- nvarchar(50)
--    @ColumnName = '״̬' -- sql_variant