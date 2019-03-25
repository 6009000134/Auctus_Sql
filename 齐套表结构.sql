--齐套率表
CREATE TABLE Auctus_FullSetRate
(
ID INT IDENTITY(1,1) PRIMARY KEY,
CreateOn DATETIME,
Rate VARCHAR(20),
Type VARCHAR(20)--后焊备料齐套率/SMT WPO齐套率/SMT计划达成率
)

--齐套分析结果
CREATE TABLE Auctus_SetCheckResult
(
CreateOn DATETIME,
DocNo VARCHAR(50),
PickLineNo INT,
Code VARCHAR(50),
Name NVARCHAR(255),
IssuedQty INT,
AcutalReqQty INT,
ReqQty INT,
ActualReqDate DATETIME,
LackAmount INT,
IsLack NVARCHAR(10),
WhAvailiableAmount INT 
)