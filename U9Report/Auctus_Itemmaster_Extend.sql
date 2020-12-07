CREATE TABLE Auctus_Itemmaster_Extend
(
Code VARCHAR(50),
ProductName NVARCHAR(300)
)

execute sp_addextendedproperty 'MS_Description','U9料号','user','dbo','table','Auctus_Itemmaster_Extend','column','Code';
execute sp_addextendedproperty 'MS_Description','UPPH项目型号','user','dbo','table','Auctus_Itemmaster_Extend','column','ProductName';
