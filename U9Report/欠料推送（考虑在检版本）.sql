
BEGIN
DECLARE @SupplierIDs VARCHAR(MAX)=''
--SET @SupplierIDs =''
SET NOCOUNT ON 

--8����ʼ����������б�
--ȡ8��Ƿ������
BEGIN 

 
 
DECLARE @SD1 DATE,@ED1 DATE
DECLARE @Date DATE=GETDATE();
SET @SD1=DATEADD(DAY,2+(-1)*DATEPART(WEEKDAY,GETDATE()),GETDATE())
SET @ED1=DATEADD(DAY,7,@SD1)

IF OBJECT_ID(N'tempdb.dbo.#tempTable',N'U') IS NULL
CREATE TABLE #tempTable
(
DocNo VARCHAR(50),
DocLineNo VARCHAR(10),
PickLineNo VARCHAR(10),
DocType NVARCHAR(20),
ProductID BIGINT,
ProductCode VARCHAR(50),
ProductName NVARCHAR(255),
ProductSPECS NVARCHAR(300),
ProductQty DECIMAL(18,0),
DemandCode VARCHAR(20),
ItemMaster BIGINT,
Code VARCHAR(30),
Name NVARCHAR(255),
SPEC NVARCHAR(600),
SafetyStockQty DECIMAL(18,0),
IssuedQty DECIMAL(18,0),
STDReqQty DECIMAL(18,0),
ActualReqQty DECIMAL(18,0),
ReqQty DECIMAL(18,0),
ActualReqDate DATE,
RN INT,
DemandCode2 VARCHAR(50),
LackAmount INT,
IsLack NVARCHAR(20),
WhavailiableAmount INT,
PRList VARCHAR(MAX),
PRApprovedQty DECIMAL(18,0),
PRFlag NVARCHAR(10),
POList VARCHAR(MAX),
POReqQtyTu DECIMAL(18,0),
RCVList VARCHAR(MAX),
ArriveQtyTU DECIMAL(18,0),
RcvQtyTU DECIMAL(18,0),
RcvFlag NVARCHAR(10),
ResultFlag NVARCHAR(30),
DescFlexField_PrivateDescSeg19 NVARCHAR(300),--�ͻ���Ʒ����
DescFlexField_PrivateDescSeg20 NVARCHAR(300),--��Ŀ����
DescFlexField_PrivateDescSeg21 NVARCHAR(300),--��Ŀ����
DescFlexField_PrivateDescSeg23 NVARCHAR(300),--ִ�вɹ�Ա
MRPCode VARCHAR(50),--MRP����
MRPCategory NVARCHAR(300),--MRP����
Buyer NVARCHAR(20),--ִ�вɹ�����
MCCode VARCHAR(20),--MC�����˱���
MCName NVARCHAR(20),--MC������
FixedLT DECIMAL(18,0),--�̶���ǰ��
ProductLine NVARCHAR(255)--��Ʒϵ��
)
ELSE
BEGIN
	TRUNCATE TABLE #tempTable
END 

--ȡÿ��7�㱸�ݵ�8����������
INSERT INTO #tempTable 
SELECT
DocNo ,
DocLineNo ,
PickLineNo ,
DocType ,
ProductID ,
ProductCode ,
ProductName ,
ProductSPECS ,
ProductQty ,
DemandCode ,
ItemMaster ,
Code ,
Name ,
SPEC ,
SafetyStockQty ,
IssuedQty ,
STDReqQty ,
ActualReqQty ,
ReqQty ,
ActualReqDate ,
RN ,
DemandCode2 ,
LackAmount ,
IsLack ,
WhavailiableAmount ,
PRList ,
PRApprovedQty ,
PRFlag ,
POList ,
POReqQtyTu ,
RCVList ,
ArriveQtyTU ,
RcvQtyTU ,
RcvFlag ,
ResultFlag ,
DescFlexField_PrivateDescSeg19 ,--�ͻ���Ʒ����
DescFlexField_PrivateDescSeg20 ,--��Ŀ����
DescFlexField_PrivateDescSeg21 ,--��Ŀ����
DescFlexField_PrivateDescSeg23 ,--ִ�вɹ�Ա
MRPCode ,--MRP����
MRPCategory ,--MRP����
Buyer ,--ִ�вɹ�����
MCCode,--MC�����˱���
MCName,--MC������
FixedLT ,--�̶���ǰ��
ProductLine --��Ʒϵ��
FROM dbo.Auctus_FullSetCheckResult8 
WHERE CONVERT(DATE,CopyDate)=@Date



--������ʵ������ʱ��=ʵ������ʱ��-ԭ���ϲɹ�������
--ί��WPOʵ������ʱ��=ʵ������ʱ��-�ɹ�����ɹ�ǰ������ǰ��-ԭ���ϲɹ�������
UPDATE #tempTable 
SET ActualReqDate=CASE WHEN #tempTable.DocNo LIKE'WPO%' THEN  DATEADD(DAY,(ISNULL(a.PurBackwardProcessLT,0)+ISNULL(b.PurForwardProcessLT,0))*(-1),ActualReqDate)
ELSE DATEADD(DAY,(ISNULL(a.PurBackwardProcessLT,0))*(-1),ActualReqDate) END 
FROM CBO_MrpInfo a,dbo.CBO_MrpInfo b WHERE a.ItemMaster=#tempTable.ItemMaster AND b.ItemMaster=#tempTable.ProductID



IF EXISTS(select * from tempdb..sysobjects where id=object_id('tempdb.dbo.#tempW8'))
BEGIN
	DROP TABLE #tempW8
END 


--8�ܻ����б�
;
WITH data1 AS
(
SELECT 
CASE WHEN a.ActualReqDate <@SD1  THEN 'w0'
WHEN a.ActualReqDate>=@SD1 AND a.ActualReqDate<@ED1 THEN 'w1'
WHEN a.ActualReqDate>=DATEADD(DAY,7,@SD1) AND a.ActualReqDate<DATEADD(DAY,7,@ED1) 
THEN 'w2'
WHEN a.ActualReqDate>=DATEADD(DAY,14,@SD1) AND a.ActualReqDate<DATEADD(DAY,14,@ED1) 
THEN 'w3'
WHEN a.ActualReqDate>=DATEADD(DAY,21,@SD1) AND a.ActualReqDate<DATEADD(DAY,21,@ED1) 
THEN 'w4'
WHEN a.ActualReqDate>=DATEADD(DAY,28,@SD1) AND a.ActualReqDate<DATEADD(DAY,28,@ED1) 
THEN 'w5'
WHEN a.ActualReqDate>=DATEADD(DAY,35,@SD1) AND a.ActualReqDate<DATEADD(DAY,35,@ED1) 
THEN 'w6'
WHEN a.ActualReqDate>=DATEADD(DAY,42,@SD1) AND a.ActualReqDate<DATEADD(DAY,42,@ED1) 
THEN 'w7'
WHEN a.ActualReqDate>=DATEADD(DAY,49,@SD1) AND a.ActualReqDate<DATEADD(DAY,49,@ED1) 
THEN 'w8'
ELSE '' END Duration
,a.MRPCategory,a.Buyer,a.MCName,a.Code,a.Name,a.SPEC,ISNULL(a.LackAmount,0)LackAmount
FROM #tempTable a 
),
data2 AS--��ר�� ����ÿ�ܵ�Ƿ������
(
SELECT * 
FROM data1 a  
PIVOT(SUM(a.LackAmount) FOR duration IN ([w0],[w1],[w2],[w3],[w4],[w5],[w6],[w7],[w8])) AS t
),
data3 AS
(
SELECT code,MAX(a.WhavailiableAmount+a.ReqQty)WhQty,min(a.WhAvailiableAmount)WhAvailiableAmount--,MIN(a.SafetyStockQty)SafetyStockQty
FROM #tempTable a  
GROUP BY a.Code 
)
SELECT a.*,b.WhQty,b.WhAvailiableAmount--,b.SafetyStockQty 
INTO #tempW8 
FROM data2  a LEFT JOIN data3 b ON a.Code=b.Code
END--End ȡ8������

--�ʼ����ݴ���
BEGIN

--��֯��	
DECLARE @Org BIGINT=(SELECT id FROM dbo.Base_Organization WHERE code='300')
--�ɹ�δ�����ݼ���
IF OBJECT_ID(N'tempdb.dbo.#tempDeficiency',N'U') IS NULL
CREATE TABLE #tempDeficiency
(
Supplier NVARCHAR(300),
Code VARCHAR(50),
DeficiencyQty DECIMAL(18,4),
IsPurchaseOrder INT,--0�ڼ��ջ���1�ɹ�δ��
RN INT
)
ELSE
BEGIN
TRUNCATE TABLE #tempDeficiency
END	


--�����ʼ�����
IF OBJECT_ID(N'tempdb.dbo.#tempSend',N'U') IS NULL
BEGIN
	CREATE TABLE #tempSend
	(Supplier NVARCHAR(300)
	,Purchaser NVARCHAR(20)
	,Email NVARCHAR(50)
	,Code VARCHAR(50)
	,Name NVARCHAR(255)
	,SPECS NVARCHAR(300)
	,w0 INT,w1 INT,w2 INT,w3 INT, w4 INT ,w5 INT ,w6 INT,w7 INT ,w8 INT
	,Total INT--8��Ƿ�ϻ���
	,RN INT--����Ӧ������ 
	)
END
ELSE
BEGIN
	TRUNCATE TABLE #tempSend
end

--��ѯ����δ����Ӧ����Ϣ
;WITH data1 AS
(
SELECT 
s.ID Supplier,a.DocNo,b.DocLineNo,b.ItemInfo_ItemCode,c.SupplierConfirmQtyTU,c.DeficiencyQtyTU,c.PlanArriveDate
,c.DeficiencyQtyCU
,c.DeficiencyQtyPU
,c.DeficiencyQtySU
,c.DeficiencyQtyTBU
,ROW_NUMBER()OVER(ORDER BY c.PlanArriveDate)RN--���ƻ�������������
--,s.DescFlexField_PrivateDescSeg3
FROM dbo.PM_PurchaseOrder a INNER JOIN dbo.PM_POLine b ON a.ID=b.PurchaseOrder
INNER JOIN dbo.PM_POShipLine c ON b.ID=c.POLine
INNER JOIN dbo.CBO_ItemMaster m ON c.ItemInfo_ItemID=m.ID
LEFT JOIN dbo.CBO_Supplier s ON a.Supplier_Supplier=s.ID LEFT JOIN dbo.CBO_Supplier_Trl s1 ON s.ID=s1.ID
WHERE a.Org=@Org AND a.Status=2 AND b.Status=2 AND c.DeficiencyQtyTU>0
--AND s.DescFlexField_PrivateDescSeg3 NOT IN('NEI01','OT01')
)
INSERT INTO #tempDeficiency
SELECT a.Supplier,a.ItemInfo_ItemCode,a.DeficiencyQtyTU,1,a.RN FROM data1 a WHERE a.ItemInfo_ItemCode='334010085'


INSERT INTO #tempDeficiency
SELECT 
a.Supplier_Supplier,b.ItemInfo_ItemCode,SUM(ISNULL(b.RcvQtyTU,0))RcvQtyTU,0,0
FROM dbo.PM_Receivement a INNER JOIN dbo.PM_RcvLine b ON a.ID=b.Receivement
WHERE a.Org=@Org
AND a.Status IN (0,3) AND b.Status IN (0,3)
AND a.ReceivementType=0 
AND b.ItemInfo_ItemCode='334010085'
GROUP BY a.Supplier_Supplier,b.ItemInfo_ItemCode



IF OBJECT_ID(N'tempdb.dbo.#tempSupResult',N'U') IS NULL
BEGIN
CREATE TABLE #tempSupResult(Supplier BIGINT,Code VARCHAR(50),IsPurchaseOrder INT,Qty INT,Duration VARCHAR(4))
END
ELSE
BEGIN
TRUNCATE TABLE #tempSupResult
END

--���㹩Ӧ�̽��ϼƻ�
DECLARE @RN INT
DECLARE @code VARCHAR(50),@w0 int,@w1 int ,@w2 int ,@w3 INT,@w4 INT,@w5 int,@w6 int ,@w7 int ,@w8 int 
DECLARE @Supplier bigint ,@code2 VARCHAR(50),@Qty decimal(18,4),@Duration varchar(4),@IsPurchaserOrder INT 
DECLARE curSup CURSOR
FOR
SELECT Code,w0,w1,w2,w3,w4,w5,w6,w7,w8 FROM #tempW8 WHERE whAvailiableAmount<0 --��ȡ��Ƿ�ϵ��Ϻ�
OPEN curSup
FETCH NEXT FROM curSup INTO @code,@w0,@w1,@w2,@w3,@w4,@w5,@w6,@w7,@w8
WHILE @@fetch_status=0
BEGIN
	DECLARE @tempLackQty INT=ISNULL(@w0,0)*(-1)--Ƿ������
	,@tempWeek VARCHAR(4)='w0'--Ƿ����
	DECLARE curDeficiency CURSOR
    FOR
	SELECT Supplier,Code,IsPurchaseOrder,DeficiencyQty,RN FROM #tempDeficiency WHERE Code=@code ORDER BY RN	--���ƻ�������������
	OPEN curDeficiency
	FETCH NEXT FROM curDeficiency INTO @Supplier,@code2,@IsPurchaserOrder,@Qty,@RN
	WHILE	@@FETCH_STATUS=0
	BEGIN
		DECLARE @QtyData INT--��������
		--����Ӧ��δ�������ܹ����㵱ǰǷ�ϣ�δ������β���Ƶ�һ���ܼ������㡣
		--���磺��һ��Ƿ��100����Ӧ�̲ɹ���δ������Ϊ1000��������900δ���Ƶ��ڶ��ܼ������㡣
		WHILE @Qty>0
		BEGIN
			WHILE ISNULL(@tempLackQty,0)=0--������Ƿ������=0��ȡ����Ƿ������
			BEGIN 
				SET @tempWeek= CASE WHEN @tempWeek='w0' THEN  'w1' 
									WHEN @tempWeek='w1' THEN  'w2' 
									WHEN @tempWeek='w2' THEN  'w3' 
									WHEN @tempWeek='w3' THEN  'w4' 
									WHEN @tempWeek='w4' THEN  'w5' 
									WHEN @tempWeek='w5' THEN  'w6' 
									WHEN @tempWeek='w6' THEN  'w7' 
									WHEN @tempWeek='w7' THEN  'w8' 
									ELSE '' END 
				SET @tempLackQty=CASE 	WHEN @tempWeek='w1' THEN  ISNULL(@w1,0)*(-1) 
										WHEN @tempWeek='w2' THEN  ISNULL(@w2,0)*(-1)
										WHEN @tempWeek='w3' THEN  ISNULL(@w3,0)*(-1)
										WHEN @tempWeek='w4' THEN  ISNULL(@w4,0)*(-1)
										WHEN @tempWeek='w5' THEN  ISNULL(@w5,0)*(-1)
										WHEN @tempWeek='w6' THEN  ISNULL(@w6,0)*(-1)
										WHEN @tempWeek='w7' THEN  ISNULL(@w7,0)*(-1)
										WHEN @tempWeek='w8' THEN  ISNULL(@w8,0)*(-1)
										ELSE 0 END 
				IF ISNULL(@tempWeek,'')=''--�������8���ˣ��˳�ѭ��
				break;
			END 
			 
			IF ISNULL(@tempWeek,'')=''
			break;--�������8���ˣ��˳�ѭ��
			IF @Qty<=@tempLackQty--��Ӧ��δ������<=����Ƿ������
			BEGIN
				SET @QtyData=@Qty
				SET @tempLackQty=@tempLackQty-@Qty
				SET @Qty=0
			END 
			ELSE--��Ӧ��δ������>����Ƿ������
            BEGIN
				SET @QtyData=@tempLackQty
				SET @Qty=@Qty-@tempLackQty
				SET @tempLackQty=0
			END 
			--���빩Ӧ�̽����ƻ�
			INSERT INTO #tempSupResult
				        ( Supplier, Code,IsPurchaseOrder, Qty, Duration )
				VALUES  ( @Supplier, -- Supplier - bigint
				          @code2, -- Code - varchar(50)
						  @IsPurchaserOrder,
				          @QtyData, -- Qty - decimal(18, 4)
				          @tempWeek  -- Duration - varchar(4)
				          )
						
		END          		       

		FETCH NEXT FROM curDeficiency INTO @Supplier,@code2,@IsPurchaserOrder,@Qty,@RN
	END 
	CLOSE curDeficiency
	DEALLOCATE curDeficiency--�ر�curDeficiency�α�    
	FETCH NEXT FROM curSup INTO @code,@w0,@w1,@w2,@w3,@w4,@w5,@w6,@w7,@w8
END 
CLOSE curSup
DEALLOCATE curSup--�ر�curSup�α� 
--SELECT * FROM #tempRcv
DELETE FROM #tempSupResult WHERE IsPurchaseOrder=0
--����������ʼ�����
IF ISNULL(@SupplierIDs,'')=''
BEGIN 
	;
	WITH data1 AS--���ݹ�Ӧ�̽����ƻ������ܡ���ר�У����ܻ���
	(
	SELECT * FROM #tempSupResult  a 
	PIVOT(SUM(a.Qty) FOR duration IN ([w0],[w1],[w2],[w3],[w4],[w5],[w6],[w7],[w8])) AS t
	),
	data2 AS--���ϺŻ���ÿ�ҹ�Ӧ��8��Ƿ������
	(
	SELECT a.Supplier,a.Code,sum(a.Qty)Total FROM #tempSupResult a GROUP BY a.Supplier,a.Code
	)
	INSERT INTO #tempSend
	SELECT a1.Name,op1.Name--,c1.Name,b.IsDefault
	,c.DefaultEmail,m.Code,m.Name,m.SPECS,r.w0,r.w1,r.w2,r.w3,r.w4,r.w5,r.w6,r.w7,r.w8,r2.Total,DENSE_RANK()OVER(ORDER BY a1.Name)RN 
	FROM data1 r INNER JOIN data2 r2 ON r.Supplier=r2.Supplier AND r.Code=r2.Code  LEFT JOIN  dbo.CBO_Supplier a ON r.Supplier=a.ID LEFT JOIN dbo.CBO_Supplier_Trl a1 ON a.ID=a1.ID
	LEFT JOIN dbo.CBO_Operators_Trl op1 ON a.Purchaser=op1.ID AND ISNULL(op1.SysMLFlag,'zh-cn')='zh-cn'
	LEFT JOIN dbo.CBO_SupplierContact b ON a.ID=b.Supplier AND b.IsDefault=1
	LEFT JOIN dbo.Base_Contact c ON b.Contact=c.ID LEFT JOIN dbo.Base_Contact_Trl c1 ON c.ID=c1.ID
	LEFT JOIN dbo.CBO_ItemMaster m ON r.Code=m.Code AND m.Org=@Org
	WHERE  a.DescFlexField_PrivateDescSeg3 NOT IN('NEI01','OT01')
END 
ELSE
BEGIN
	;
	WITH data1 AS--���ݹ�Ӧ�̽����ƻ������ܡ���ר�У����ܻ���
	(
	SELECT * FROM #tempSupResult  a 
	PIVOT(SUM(a.Qty) FOR duration IN ([w0],[w1],[w2],[w3],[w4],[w5],[w6],[w7],[w8])) AS t
	),
	data2 AS--���ϺŻ���ÿ�ҹ�Ӧ��8��Ƿ������
	(
	SELECT a.Supplier,a.Code,sum(a.Qty)Total FROM #tempSupResult a GROUP BY a.Supplier,a.Code
	)
	INSERT INTO #tempSend
	SELECT a1.Name,ISNULL(op1.Name,'')--,c1.Name,b.IsDefault
	,ISNULL(c.DefaultEmail,'')DefaultEmail,m.Code,m.Name,m.SPECS,ISNULL(r.w0,0)w0,ISNULL(r.w1,0)w1,ISNULL(r.w2,0)w2,ISNULL(r.w3,0)w3
	,ISNULL(r.w4,0)w4,ISNULL(r.w5,0)w5,ISNULL(r.w6,0)w6,ISNULL(r.w7,0)w7,ISNULL(r.w8,0)w8,ISNULL(r2.Total,0)Total,DENSE_RANK()OVER(ORDER BY a1.Name)RN 
	FROM data1 r INNER JOIN data2 r2 ON r.Supplier=r2.Supplier AND r.Code=r2.Code  LEFT JOIN  dbo.CBO_Supplier a ON r.Supplier=a.ID LEFT JOIN dbo.CBO_Supplier_Trl a1 ON a.ID=a1.ID
	LEFT JOIN dbo.CBO_Operators_Trl op1 ON a.Purchaser=op1.ID AND ISNULL(op1.SysMLFlag,'zh-cn')='zh-cn'
	LEFT JOIN dbo.CBO_SupplierContact b ON a.ID=b.Supplier AND b.IsDefault=1
	LEFT JOIN dbo.Base_Contact c ON b.Contact=c.ID LEFT JOIN dbo.Base_Contact_Trl c1 ON c.ID=c1.ID
	LEFT JOIN dbo.CBO_ItemMaster m ON r.Code=m.Code AND m.Org=@Org
	WHERE r.Supplier IN (SELECT strid FROM dbo.fun_Cust_StrToTable(@SupplierIDs))
	AND  a.DescFlexField_PrivateDescSeg3 NOT IN('NEI01','OT01')
END 
--�����乩Ӧ������ȥ��
SELECT DISTINCT a.Supplier
--,a.Email
--,'liufei@auctus.com' Email
,'chenll@auctus.cn;buyerpm01@auctus.cn;yangm@auctus.cn;hudz@auctus.cn;liufei@auctus.com;' Email
--,'491675469@qq.com'Email
--,'liufei@auctus.com' Email
,a.Purchaser
--,(SELECT c.DefaultEmail+';' FROM dbo.CBO_ItemMaster m 
--LEFT JOIN dbo.CBO_Operators op ON op.Code=m.DescFlexField_PrivateDescSeg23
--LEFT JOIN dbo.Base_Contact c ON op.Contact=c.ID
--WHERE m.Org=1001708020135665 AND m.Code=a.Code FOR XML PATH(''))CC
,DENSE_RANK()OVER(ORDER BY RN)OrderNo
FROM #tempSend a 
WHERE ISNULL(a.Email,'')=''
--��Ӧ���ʼ�������Ϣ
SELECT  
--s.Supplier,
a.Supplier,a.Purchaser
,a.Code,a.Name,a.SPECS,a.w0,a.w1,a.w2,a.w3,a.w4,a.w5,a.w6,a.w7,a.w8,a.Total
,a.Email
,(SELECT c.DefaultEmail+';' FROM dbo.CBO_ItemMaster m 
LEFT JOIN dbo.CBO_Operators op ON op.Code=m.DescFlexField_PrivateDescSeg23
LEFT JOIN dbo.Base_Contact c ON op.Contact=c.ID
WHERE m.Org=1001708020135665 AND m.Code=a.Code FOR XML PATH(''))CC 
--,'hudz@auctus.cn;liufei@auctus.com;' Email
--,'heqh@aucuts.cn;' Email
--,'liufei@auctus.com;' CC
,DENSE_RANK()OVER(ORDER BY RN)OrderNo
FROM #tempSend a 
INNER JOIN 
(SELECT t1.Name FROM (SELECT DISTINCT Supplier FROM #tempDeficiency WHERE IsPurchaseOrder=0)t INNER JOIN dbo.CBO_Supplier_Trl t1 ON t.Supplier=t1.ID)b ON a.Supplier=b.Name
WHERE ISNULL(a.Email,'')<>'' AND a.Supplier='��ݸ�й��׵��ӿƼ����޹�˾' AND a.Code='334010085'
--WHERE ISNULL(a.Email,'')='111231231232131'
END 

END 
SELECT * FROM #tempDeficiency WHERE Code='334010085'
SELECT * FROM #tempW8 WHERE code='334010085'
