CREATE TABLE Auctus_ProjectBonus
(
ID INT,
xmbm VARCHAR(50),
jjje DECIMAL(18,2),
ffyf VARCHAR(10),
modedatacreater  VARCHAR(20),
modedatacreateddate DATETIME,
modedatamodifier VARCHAR(20),
modedatamodifydate datetime
)

EXECUTE sp_addextendedproperty 'MS_Description','项目ID','user','dbo','table','Auctus_ProjectBonus','column','xmbm';
execute sp_addextendedproperty 'MS_Description','发放金额','user','dbo','table','Auctus_ProjectBonus','column','jjje';
execute sp_addextendedproperty 'MS_Description','发放月份','user','dbo','table','Auctus_ProjectBonus','column','ffyf';
execute sp_addextendedproperty 'MS_Description','创建人','user','dbo','table','Auctus_ProjectBonus','column','modedatacreater';
execute sp_addextendedproperty 'MS_Description','创建时间','user','dbo','table','Auctus_ProjectBonus','column','modedatacreateddate';
execute sp_addextendedproperty 'MS_Description','修改人','user','dbo','table','Auctus_ProjectBonus','column','modedatamodifier';
execute sp_addextendedproperty 'MS_Description','修改时间','user','dbo','table','Auctus_ProjectBonus','column','modedatamodifydate';


CREATE TABLE Auctus_Salary
(
ID INT,
sjpjgz VARCHAR(50),
modedatacreater  VARCHAR(20),
modedatacreateddate DATETIME,
modedatamodifier VARCHAR(20),
modedatamodifydate datetime
)

execute sp_addextendedproperty 'MS_Description','实际平均工资','user','dbo','table','Auctus_Salary','column','sjpjgz';
execute sp_addextendedproperty 'MS_Description','创建人','user','dbo','table','Auctus_Salary','column','modedatacreater';
execute sp_addextendedproperty 'MS_Description','创建时间','user','dbo','table','Auctus_Salary','column','modedatacreateddate';
execute sp_addextendedproperty 'MS_Description','修改人','user','dbo','table','Auctus_Salary','column','modedatamodifier';
execute sp_addextendedproperty 'MS_Description','修改时间','user','dbo','table','Auctus_Salary','column','modedatamodifydate';


CREATE TABLE Auctus_ProjectBudget
(
ID INT,
xmbm VARCHAR(50),
yjgst DECIMAL(18,2),
rjgst DECIMAL(18,2),
jggst DECIMAL(18,2),
csgst DECIMAL(18,2),
yszgst DECIMAL(18,2),
sbf   DECIMAL(18,2),
dyscf DECIMAL(18,2),
zjf    DECIMAL(18,2),
ycsf DECIMAL(18,2),
zsrzf DECIMAL(18,2),
altcsf DECIMAL(18,2),
scf   DECIMAL(18,2),
yfrlf DECIMAL(18,2),
xmjjf DECIMAL(18,2),
modedatacreater  VARCHAR(20),
modedatacreateddate DATETIME,
modedatamodifier VARCHAR(20),
modedatamodifydate datetime
)

execute sp_addextendedproperty 'MS_Description','项目ID','user','dbo','table','Auctus_ProjectBudget','column','xmbm';
execute sp_addextendedproperty 'MS_Description','硬件工时/天','user','dbo','table','Auctus_ProjectBudget','column','yjgst';
execute sp_addextendedproperty 'MS_Description','软件工时/天','user','dbo','table','Auctus_ProjectBudget','column','rjgst';
execute sp_addextendedproperty 'MS_Description','结果工时/天','user','dbo','table','Auctus_ProjectBudget','column','jggst';
execute sp_addextendedproperty 'MS_Description','测试工时/天','user','dbo','table','Auctus_ProjectBudget','column','csgst';
execute sp_addextendedproperty 'MS_Description','预算总工时/天','user','dbo','table','Auctus_ProjectBudget','column','yszgst';
execute sp_addextendedproperty 'MS_Description','手板费','user','dbo','table','Auctus_ProjectBudget','column','sbf';
execute sp_addextendedproperty 'MS_Description','打样生产费','user','dbo','table','Auctus_ProjectBudget','column','dyscf';
execute sp_addextendedproperty 'MS_Description','治具费','user','dbo','table','Auctus_ProjectBudget','column','zjf';
execute sp_addextendedproperty 'MS_Description','预测试费','user','dbo','table','Auctus_ProjectBudget','column','ycsf';
execute sp_addextendedproperty 'MS_Description','正式认证费','user','dbo','table','Auctus_ProjectBudget','column','zsrzf';
execute sp_addextendedproperty 'MS_Description','ALT测试费','user','dbo','table','Auctus_ProjectBudget','column','altcsf';
execute sp_addextendedproperty 'MS_Description','试产费','user','dbo','table','Auctus_ProjectBudget','column','scf';
execute sp_addextendedproperty 'MS_Description','研发人力费','user','dbo','table','Auctus_ProjectBudget','column','yfrlf';
execute sp_addextendedproperty 'MS_Description','项目奖金费','user','dbo','table','Auctus_ProjectBudget','column','xmjjf';
execute sp_addextendedproperty 'MS_Description','创建人','user','dbo','table','Auctus_ProjectBudget','column','modedatacreater';
execute sp_addextendedproperty 'MS_Description','创建时间','user','dbo','table','Auctus_ProjectBudget','column','modedatacreateddate';
execute sp_addextendedproperty 'MS_Description','修改人','user','dbo','table','Auctus_ProjectBudget','column','modedatamodifier';
execute sp_addextendedproperty 'MS_Description','修改时间','user','dbo','table','Auctus_ProjectBudget','column','modedatamodifydate';


