CREATE TABLE Auctus_ProductResource
(
ID INT PRIMARY KEY IDENTITY(1,1),
CreatedOn DATETIME,
CreateBy NVARCHAR(20),
Code VARCHAR(50),
Name Nvarchar(50),
Num DECIMAL(18,2),
WorkHours decimal(18,2)
)
EXECUTE sp_addextendedproperty 'MS_Description','线别编码','user','dbo','table','Auctus_ProductResource','column','Code';
EXECUTE sp_addextendedproperty 'MS_Description','线别名称','user','dbo','table','Auctus_ProductResource','column','Name';
EXECUTE sp_addextendedproperty 'MS_Description','人数','user','dbo','table','Auctus_ProductResource','column','Num';
EXECUTE sp_addextendedproperty 'MS_Description','工时','user','dbo','table','Auctus_ProductResource','column','WorkHours';

--INSERT INTO dbo.Auctus_ProductResource
--        ( CreatedOn ,CreateBy ,Code ,Name ,Num ,WorkHours
--        )
--VALUES  ( GETDATE() ,
--          N'' , 
--          '' , 
--          N'' , 
--          NULL ,
--          NULL  
--        )
