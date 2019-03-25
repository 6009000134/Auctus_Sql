/*
SMT��������������
*/
ALTER PROC sp_Auctus_SMTFullSetRate
(
@Date DATETIME,
@Org BIGINT
)
AS
BEGIN

--DECLARE @Date DATETIME=GETDATE()
--DECLARE @Org BIGINT=(SELECT ID FROM dbo.Base_Organization WHERE code='300')
--EXEC sp_Auctus_GetLackDoc @Date,@Org

--���׷������
IF OBJECT_ID(N'tempdb.dbo.#tempLackDoc',N'U') IS NULL
BEGIN 
CREATE TABLE #tempLackDoc
(
DocNo VARCHAR(50),
ActualReqQty DATETIME
)
END 
ELSE
BEGIN 
TRUNCATE TABLE #tempLackDoc
END 
--ִ�����׷����Ĵ洢���̣�ץ��ĿǰΪֹδ���׵���Ʒ
--EXEC sp_Auctus_GetLackDoc @Date,@Org
INSERT INTO #tempLackDoc
SELECT  a.DocNo,MAX(a.ActualReqDate)ActualReqDate
FROM dbo.Auctus_SetCheckResult a
WHERE a.LackAmount<0
GROUP BY a.DocNo

DECLARE @i DECIMAL(18,4)
DECLARE @result DECIMAL(18,4)
;
WITH PickList AS
(
SELECT a.DocNo,d.PickLineNo
,d.ItemInfo_ItemID Item,d.ItemInfo_ItemCode,d.ItemInfo_ItemName
,b.PurQtyTU--�ɹ�����1 ��������
,d.IssuedQty--�ѷ�������  
,d.STDReqQty--��׼����
,d.ActualReqQty--ʵ����������	
,d.ActualReqQty-d.IssuedQty ReqQty--
,d.ActualReqDate--ʵ��������
,e.DeliveryDate
,ROW_NUMBER() OVER(ORDER BY d.ActualReqDate) RN 
FROM dbo.PM_PurchaseOrder a INNER JOIN dbo.PM_POLine b ON a.ID=b.PurchaseOrder 
LEFT JOIN dbo.CBO_SCMPickHead c ON b.SCMPickHead=c.ID LEFT JOIN dbo.CBO_SCMPickList d ON d.PicKHead=c.ID
LEFT JOIN dbo.PM_POShipLine e ON e.POLine=b.ID
WHERE a.Status in(0,1,2) and b.Status in (0,1,2) AND a.Org=(SELECT ID FROM dbo.Base_Organization WHERE code='300') --AND d.ActualReqDate BETWEEN @StartDate AND @EndDate
AND EXISTS(select 1 from PM_POShipLine b1  where e.ID=b1.ID)
AND c.ID IS NOT NULL
AND d.ActualReqQty>0
AND d.IssuedQty<d.ActualReqQty
AND d.IssueStyle<>2
AND DATEADD(DAY,-3,d.ActualReqDate)<GETDATE()
),
WPO AS
(
SELECT DISTINCT DocNo FROM PickList
),
LackDoc AS
(
SELECT * FROM #tempLackDoc
)
SELECT @result=((SELECT COUNT(*) FROM WPO a LEFT JOIN #tempLackDoc b ON a.DocNo=b.DocNo
WHERE b.DocNo IS NULL)/(SELECT CONVERT(DECIMAL(18,6),COUNT(*)) FROM WPO))
--
INSERT INTO Auctus_FullSetRate(CreateON,Rate,Type) VALUES(GETDATE(),@result*100,'SMT')
SELECT CONVERT(VARCHAR(10),@result*100)+'%'
END 

--�����ʱ�
--CREATE TABLE Auctus_FullSetRate
--(
--ID INT IDENTITY(1,1) PRIMARY KEY,
--CreateOn DATETIME,
--Rate VARCHAR(20),
--Type VARCHAR(20)--�󺸱���������/SMT WPO������/SMT�ƻ������
--)

----���׷������
--CREATE TABLE Auctus_SetCheckResult
--(
--CreateOn DATETIME,
--DocNo VARCHAR(50),
--PickLineNo INT,
--Code VARCHAR(50),
--Name NVARCHAR(255),
--IssuedQty INT,
--AcutalReqQty INT,
--ReqQty INT,
--ActualReqDate DATETIME,
--LackAmount INT,
--IsLack NVARCHAR(10),
--WhAvailiableAmount INT 
--)

--�����б�



