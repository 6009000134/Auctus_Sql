CREATE TABLE Auctus_Itemmaster_Extend
(
Code VARCHAR(50),
ProductName NVARCHAR(300)
)

execute sp_addextendedproperty 'MS_Description','U9�Ϻ�','user','dbo','table','Auctus_Itemmaster_Extend','column','Code';
execute sp_addextendedproperty 'MS_Description','UPPH��Ŀ�ͺ�','user','dbo','table','Auctus_Itemmaster_Extend','column','ProductName';
