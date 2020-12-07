/*
U9工单表数据保存在此表
*/

CREATE TABLE mxqh_U9MO
(
CreatedDate DATETIME,
DocNo VARCHAR(50),
MaterialID INT,
MaterialCode VARCHAR(50),
MaterialName NVARCHAR(300),
ProductQty INT,
ERPSO VARCHAR(200),
ERPQuantity INT,
CustomerOrder VARCHAR(50),
Address1 NVARCHAR(200),
Country NVARCHAR(50),
SendPlaceCode NVARCHAR(100),
SendPlace NVARCHAR(100),
Department NVARCHAR(20)
)

