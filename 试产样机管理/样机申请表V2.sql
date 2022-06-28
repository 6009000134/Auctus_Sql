--SELECT * FROM dbo.TP_SampleApplication

CREATE TABLE TP_SampleRequest
(
OAFlowID INT PRIMARY KEY,
MainID INT,
CreatedBy VARCHAR(30),
CreatedDate DATE,
Type VARCHAR(10)
)

CREATE TABLE TP_SampleRequest_Detail
(
OAFlowID int,
ID int PRIMARY KEY,
NAME varchar(300),
Qty int,
Request nvarchar(2000),
RequireDate date,
ReqUse varchar(50)
)

CREATE TABLE TP_SampleRequest_Detail1
(
OAFlowID INT,
ID INT PRIMARY KEY,
Code VARCHAR(30),
Name NVARCHAR(300),
Qty INT,
Version VARCHAR(50),
ProductPower VARCHAR(50),
SoundCode VARCHAR(50),
Frequency VARCHAR(200),
Mode VARCHAR(300),
SpcialRequset varchar(2000),
CerRequirement varchar(50),
DeliveryDate Date,
IsNeedRpt bit
)

