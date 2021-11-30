USE [AuctusERP]
GO
/****** Object:  StoredProcedure [dbo].[sp_Auctus_GetShipData1846]    Script Date: 2021/10/29 15:48:15 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
�����ţ�����
�����ˣ���ٻ
ʱ�䣺2021-10-27
����
���1846�ĳ�������1����2�������Ϻŵ�ֱ��ȡ��
2���Ϻŵģ����ж�Ӳ���Ϻź�����Ϻ������Ƿ����
����ȣ���ȡ��Ӳ���Ϻż�����������۸��Ӳ���۸��ۼ���������
������ȣ���ԭʼ���������ݵ���
*/
ALTER PROC [dbo].[sp_Auctus_GetShipData1846]
(
@Org VARCHAR(200),
@DocType NVARCHAR(1000),
@StartDate DATE,
@EndDate DATE
)
AS
--DECLARE @StartDate DATE='2020-09-15'
--,@EndDate DATE='2021-09-26'
SET @EndDate=DATEADD(DAY,1,@EndDate)
SET @Org=REPLACE(@Org,';',',')
;
WITH data1 AS
(
SELECT a.DocNo,op1.Name '����Ա',cus.ShortName,cus1.Name CustomerName
,m.Code,m.Name,mat.Name ProductType,FORMAT(b.ShipConfirmDate,'yyyy/MM/dd')ShipConfirmDate
--,b.OrderPrice*a.ACToFCExRate/(1+b.TaxRate)Price
,CASE WHEN a.Org=1001712010015192 THEN CONVERT(DECIMAL(18,10),dbo.fn_CustGetCurrentRate(a.AC,1,b.ShipConfirmDate,2)*b.FinallyPrice) 
WHEN a.AC=1 THEN CONVERT(DECIMAL(18,10),b.FinallyPrice/(1+b.TaxRate)) 
ELSE CONVERT(DECIMAL(18,10),a.ACToFCExRate*b.FinallyPrice)
END Price
,CONVERT(INT,b.ShipQtyTUAmount)ShipQtyTUAmount
,CASE WHEN a.Org=1001712010015192 THEN CONVERT(DECIMAL(18,10),dbo.fn_CustGetCurrentRate(a.AC,1,b.ShipConfirmDate,2)*b.FinallyPrice) 
WHEN a.AC=1 THEN CONVERT(DECIMAL(18,10),b.FinallyPrice/(1+b.TaxRate)) 
ELSE CONVERT(DECIMAL(18,10),a.ACToFCExRate*b.FinallyPrice)
END*b.ShipQtyTUAmount TotalMoney
,cur1.Name CurrencyName
,ROW_NUMBER() OVER(PARTITION BY a.DocNo ORDER BY m.code)RN
,o1.Name OrgName
FROM sm_ship a INNER JOIN dbo.SM_ShipLine b ON a.id=b.Ship
LEFT JOIN dbo.CBO_Operators op ON b.DescFlexField_PubDescSeg6=op.code
LEFT JOIN dbo.CBO_Operators_Trl op1 ON op.ID=op1.ID AND op1.SysMLFlag='zh-cn'
LEFT JOIN dbo.CBO_Customer cus ON a.OrderBy_Customer=cus.ID LEFT JOIN dbo.CBO_Customer_Trl cus1 ON cus.ID=cus1.ID AND cus1.SysMLFlag='zh-cn'
LEFT JOIN dbo.CBO_ItemMaster m ON b.ItemInfo_ItemID=m.ID
LEFT JOIN vw_MatCategory mat ON m.DescFlexField_PrivateDescSeg9=mat.code
LEFT JOIN dbo.Base_Currency cur ON a.AC=cur.ID LEFT JOIN dbo.Base_Currency_Trl cur1 ON cur.ID=cur1.ID AND cur1.SysMLFlag='zh-cn'
LEFT JOIN dbo.Base_Organization o ON a.Org=o.ID LEFT JOIN dbo.Base_Organization_Trl o1 ON o.ID=o1.ID AND o1.SysMLFlag='zh-cn'
LEFT JOIN dbo.SM_ShipDocType doc ON a.DocumentType=doc.ID LEFT JOIN dbo.SM_ShipDocType_Trl doc1 ON doc.ID=doc1.ID
WHERE m.Name LIKE '%AT1846%'
AND a.ShipConfirmDate>=@StartDate AND a.ShipConfirmDate<@EndDate
AND a.Status=3--�����
AND a.Org IN (SELECT strID FROM dbo.fun_Cust_StrToTable(@Org)) 
AND doc1.name IN (SELECT strID FROM dbo.fun_Cust_StrToTable(@DocType))
--AND a.DocNo='SM20202109037'
--AND a.AC=9
--ORDER BY a.DocNo
),
data2 AS
(
SELECT a.DocNo,a.Code,a.Name,SUM(a.ShipQtyTUAmount)Qty,SUM(a.Price*a.ShipQtyTUAmount)/SUM(a.ShipQtyTUAmount)Price,SUM(a.Price*a.ShipQtyTUAmount)TotalMoney
FROM data1 a 
GROUP BY a.Code,a.DocNo,a.Name
),
ItemInfo AS
(
SELECT a.DocNo,COUNT(1)ItemCount  FROM data2 a GROUP BY a.DocNo
),
UnStandardData1 AS--1���Ϻŵĳ�����
(
SELECT a.DocNo,SUM(a.ShipQtyTUAmount)ShipQtyTUAmount,SUM(a.Price*a.ShipQtyTUAmount)/SUM(a.ShipQtyTUAmount)Price,SUM(a.Price*a.ShipQtyTUAmount)TotalMoney,'1���Ϻ�'ItemCount FROM data1 a WHERE a.DocNo IN (SELECT DocNo FROM ItemInfo WHERE ItemCount=1)
GROUP BY a.DocNo
),
UnStandardData3 AS--3���Ϻŵĳ�����
(
SELECT *,'2�������Ϻ�'ItemCount FROM data1 a WHERE a.DocNo IN (SELECT DocNo FROM ItemInfo WHERE ItemCount>2)
),
StandardData AS--2���Ϻŵĳ�����
(
SELECT * FROM data2 a WHERE a.DocNo IN (SELECT DocNo FROM ItemInfo WHERE ItemCount=2)
),
StandardData2 AS
(
SELECT 
a.DocNo,a.Code,CASE WHEN a.Qty=b.Qty THEN '�������' ELSE '���������' END Flag,a.Price,a.Qty,a.TotalMoney
FROM StandardData a INNER JOIN StandardData b ON a.DocNo=b.DocNo AND a.Code!=b.Code AND a.Code NOT LIKE  '%S4%'
),
UnStandardData4 AS
(
SELECT *,'2���Ϻ�����������'ItemCount FROM data1 a WHERE a.DocNo IN (SELECT a.DocNo FROM StandardData2 a WHERE a.Flag='���������')
),
StandardData3 AS
(
SELECT a.DocNo,MIN(a.Qty) Qty,SUM(a.Price*a.Qty)/MIN(a.Qty)Price,SUM(a.Price*a.Qty)TotalMoney
FROM data2 a WHERE a.DocNo IN (SELECT a.DocNo FROM StandardData2 a WHERE a.Flag='�������')
GROUP BY a.DocNo
)
SELECT b.DocNo,b.����Ա,b.ShortName,b.CustomerName,b.Code,b.Name,b.ProductType,b.ShipConfirmDate,a.Price,a.ShipQtyTUAmount,a.TotalMoney,b.CurrencyName
,b.RN,'2'ItemCount ,b.OrgName
FROM UnStandardData1 a LEFT JOIN data1 b ON a.DocNo=b.DocNo AND b.RN=1
UNION ALL 
SELECT * FROM UnStandardData3
UNION ALL
SELECT * FROM UnStandardData4
UNION all
SELECT b.DocNo,b.����Ա,b.ShortName,b.CustomerName,b.Code,b.Name,b.ProductType,b.ShipConfirmDate,a.Price,a.Qty,a.TotalMoney,b.CurrencyName
,b.RN,'2'ItemCount ,b.OrgName
FROM StandardData3 a LEFT JOIN data1 b ON a.DocNo=b.DocNo AND b.RN=1

