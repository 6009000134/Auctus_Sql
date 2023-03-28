--select * FROM dbo.Auctus_ItemMaster_Extend
IF OBJECT_ID(N'tempdb.dbo.#tempItem',N'U') IS NULL
CREATE TABLE #tempItem
(
ID bigint,
Code VARCHAR(20),
Name NVARCHAR(300),
SPECS NVARCHAR(600),
Buyer VARCHAR(20),
ProjectCode VARCHAR(MAX),
RelateBom VARCHAR(MAX),
Effective_IsEffective BIT)
ELSE
TRUNCATE TABLE #tempItem

IF OBJECT_ID(N'tempdb.dbo.#tempRcvData',N'U') IS NULL
CREATE TABLE #tempRcvData
(
Code VARCHAR(20),
Price DECIMAL(18,9)
)
ELSE
TRUNCATE TABLE #tempRcvData
INSERT INTO #tempRcvData
        ( Code, Price )
SELECT t.ItemInfo_ItemCode,t.Price FROM (
SELECT a.CreatedOn,a.DocNo,b.FinallyPriceTC,b.FinallyPriceAC,a.TC,a.AC ,b.ItemInfo_ItemCode
,ISNULL(b.FinallyPriceAC*dbo.fn_CustGetCurrentRate(a.AC,1,a.CreatedOn,2),b.FinallyPriceAC)Price
,ROW_NUMBER() OVER(PARTITION BY b.ItemInfo_ItemCode ORDER BY b.CreatedOn DESC)RN
FROM dbo.PM_Receivement a INNER JOIN dbo.PM_RcvLine b ON a.ID=b.Receivement 
WHERE a.Org=(SELECT id FROM dbo.Base_Organization WHERE code='300')
AND a.ReceivementType=0
)t WHERE t.RN=1
IF OBJECT_ID(N'tempdb.dbo.#tempWh',N'U') IS NULL
CREATE TABLE #tempWh
(
CostFieldName VARCHAR(50),
Code VARCHAR(20),
BalQty INT 
)
ELSE
TRUNCATE TABLE #tempWh

INSERT INTO #tempWh
        ( CostFieldName, Code, BalQty )
SELECT c1.Name,a.Code,SUM(a.BalQty)BalQty
FROM dbo.v_Cust_InvInfo4OA a  LEFT JOIN dbo.CBO_CostFieldObject b ON a.Wh_ID=b.Warehouse 
LEFT JOIN dbo.CBO_CostField c ON b.CostField=c.ID
LEFT JOIN dbo.CBO_CostField_Trl c1 ON c.ID=c1.ID AND c1.SysMLFlag='zh-cn'
WHERE (PATINDEX('3%',a.code)>0 OR PATINDEX('2%',a.code)>0 OR PATINDEX('1%',a.code)>0) 
AND a.BalQty>0 AND a.OrgCode='300'
AND c1.Name='��ɱ�'
GROUP BY c1.name,a.code 
UNION ALL
SELECT c1.Name,a.Code,SUM(a.BalQty)BalQty
FROM dbo.v_Cust_InvInfo4OA a  LEFT JOIN dbo.CBO_CostFieldObject b ON a.Wh_ID=b.Warehouse 
LEFT JOIN dbo.CBO_CostField c ON b.CostField=c.ID
LEFT JOIN dbo.CBO_CostField_Trl c1 ON c.ID=c1.ID AND c1.SysMLFlag='zh-cn'
WHERE (PATINDEX('3%',a.code)>0 OR PATINDEX('2%',a.code)>0 OR PATINDEX('1%',a.code)>0) 
AND a.BalQty>0 AND a.OrgCode='300'
AND c1.Name!='��ɱ�'
GROUP BY c1.name,a.code 

IF OBJECT_ID(N'tempdb.dbo.#tempPurInfo',N'U') IS NULL
CREATE TABLE #tempPurInfo
(
Code VARCHAR(20),
DeficienctyQtyTU INT 
)
ELSE
TRUNCATE TABLE #tempPurInfo
INSERT INTO #tempPurInfo
        ( Code, DeficienctyQtyTU )
SELECT 
--a.ID,a.DocNo,a.CreatedOn,b.DocLineNo,c.SubLineNo,c.ItemInfo_ItemCode,c.DeficiencyQtyTU
b.ItemInfo_ItemCode,SUM(c.DeficiencyQtyTU)DeficienctyQtyTU
FROM dbo.PM_PurchaseOrder a INNER JOIN dbo.PM_POLine b ON a.ID=b.PurchaseOrder INNER JOIN dbo.PM_POShipLine c ON b.ID=c.POLine
WHERE (PATINDEX('3%',b.ItemInfo_ItemCode)>0 OR PATINDEX('2%',b.ItemInfo_ItemCode)>0 OR PATINDEX('1%',b.ItemInfo_ItemCode)>0)
AND a.Org=(SELECT ID FROM base_Organization WHERE Code='300')
AND b.Status=2
AND c.DeficiencyQtyTU>0
GROUP BY b.ItemInfo_ItemCode





IF OBJECT_ID(N'tempdb.dbo.#tempResult',N'U') IS NOT NULL
DROP TABLE #tempResult
;
WITH ItemInfo AS
(
SELECT
m.ID,m.Code,m.Name,m.SPECS,m.Effective_IsEffective
,m.DescFlexField_PrivateDescSeg23,m.DescFlexField_PrivateDescSeg22
FROM dbo.CBO_ItemMaster m
WHERE 
m.Code IN (SELECT code FROM #tempWh UNION ALL SELECT code FROM #tempPurInfo)and m.Org=(SELECT ID FROM base_Organization WHERE Code='300')
)
SELECT a.ID,mrp.Name MRP����,a.Code,a.Name,a.SPECS,ae.PLM_TypeName 
,(SELECT t.Price FROM #tempRcvData t WHERE t.Code=a.Code)���һ���ջ���_�����
,o1.Name Buyer
--,'��Ŀ����' ProjectCode
--,'��Ŀ����'
,(SELECT MAX(t.CreatedOn) FROM dbo.PM_POLine t INNER JOIN dbo.PM_PurchaseOrder t1 ON t.PurchaseOrder=t1.ID WHERE t.ItemInfo_ItemCode=a.Code AND t1.Org=(SELECT ID FROM base_Organization WHERE Code='300') GROUP BY t.ItemInfo_ItemCode)���һ��POʱ��
,(SELECT ISNULL(SUM(t.BalQty),0) FROM dbo.v_Cust_InvInfo4OA t WHERE t.Code=a.Code AND t.OrgCode='300' AND t.Wh_Name LIKE '����%' GROUP BY t.Code)���ϲ�����
,(SELECT ISNULL(t.BalQty,0) FROM #tempWh t WHERE t.CostFieldName='��ɱ�' AND t.Code=a.Code)��ɱ�������_�����ϲ�
,(SELECT ISNULL(SUM(t.BalQty),0) FROM #tempWh t WHERE t.CostFieldName!='��ɱ�' AND t.Code=a.Code group by t.Code)���������_������ɱ�
,(SELECT ISNULL(SUM(LackAmount)*(-1),0) FROM dbo.Auctus_FullSetCheckResult8 t WHERE t.Code=a.Code AND t.CopyDate>'2023-02-14'
GROUP BY Code)����Ƿ��
,(SELECT ISNULL(SUM(t.ActualReqQty),0) FROM dbo.Auctus_FullSetCheckResult8 t WHERE t.Code=a.Code AND t.CopyDate>'2023-02-14'
GROUP BY Code)��������
INTO #tempResult
FROM ItemInfo a 
LEFT JOIN dbo.vw_MRPCategory mrp ON a.DescFlexField_PrivateDescSeg22=mrp.Code
LEFT JOIN dbo.Auctus_ItemMaster_Extend ae ON a.Code=ae.Code
LEFT JOIN dbo.CBO_Operators o ON a.DescFlexField_PrivateDescSeg23=o.Code LEFT JOIN dbo.CBO_Operators_Trl o1 ON o.id=o1.ID AND o1.SysMLFlag='zh-cn'
--WHERE a.Code='335130751'


IF OBJECT_ID(N'tempdb.dbo.#TempTable',N'U') IS NOT NULL
DROP TABLE #TempTable
SELECT DISTINCT mrp.Name MRPName,a.Code,m2.Name,m2.SPECS,a.MasterCode ProductCode,m.Name ProductName
,m.DescFlexField_PrivateDescSeg20 ProjectCode
,(SELECT a.Name FROM dbo.v_Cust_KeyValue WHERE GroupCode='RDProject' AND Code=m.DescFlexField_PrivateDescSeg20) ProjectName
INTO #TempTable
FROM dbo.Auctus_NewestBom a LEFT JOIN dbo.CBO_ItemMaster m ON a.MasterCode=m.code AND m.Org=(SELECT id FROM dbo.Base_Organization WHERE code='300')
LEFT JOIN dbo.CBO_ItemMaster m2 ON a.Code=m2.Code AND m2.Org=(SELECT id FROM dbo.Base_Organization WHERE code='300')
LEFT JOIN dbo.vw_MRPCategory mrp ON m2.DescFlexField_PrivateDescSeg22=mrp.Code
WHERE 1=1 AND a.MasterCode LIKE '1%' AND a.Code IN (
SELECT code FROM #tempResult)

IF OBJECT_ID(N'tempdb.dbo.#TempTable2',N'U') IS NOT NULL
DROP TABLE #TempTable2
SELECT DISTINCT a.MRPName MRP����,a.Code �Ϻ�,a.Name Ʒ��,a.SPECS ���
--,a.ProductCode  BOM�Ϻ�
--,a.ProductName BOMƷ��
,(SELECT b.ProductCode+'||' FROM #TempTable b WHERE b.code=a.Code FOR XML PATH('')) ��Ʒ�Ϻ�
,(SELECT b.ProductName+'||' FROM #TempTable b WHERE b.code=a.Code FOR XML PATH('')) ��ƷƷ��
,(SELECT b.ProjectCode+'||' FROM #TempTable b WHERE b.code=a.Code FOR XML PATH('')) ��Ʒ��Ŀ����
,(SELECT b.ProjectName+'||' FROM #TempTable b WHERE b.code=a.Code FOR XML PATH('')) ��Ʒ��Ŀ����
INTO #tempTable2
FROM #TempTable a 
--ORDER BY a.Code


SELECT * INTO #TempPrice1 FROM 
(SELECT a.Code,a.Price,a.CostStorePrice,ROW_NUMBER()OVER(PARTITION BY a.Code ORDER BY a.LogTime desc)RN 
FROM dbo.Auctus_ItemStandardPrice a WHERE a.Code IN (SELECT Code FROM #tempResult) AND ISNULL(a.CostStorePrice,0)!=0)
t WHERE t.RN=1
SELECT * INTO #TempPrice2
FROM 
(SELECT a.Code,a.Price,a.CostStorePrice,ROW_NUMBER()OVER(PARTITION BY a.Code ORDER BY a.LogTime desc)RN FROM dbo.Auctus_ItemStandardPrice a WHERE a.Code IN (SELECT Code FROM #tempResult) AND ISNULL(a.Price,0)!=0)
t WHERE t.RN=1

SELECT 
a.MRP����,a.Code �Ϻ�,a.Name Ʒ��,a.SPECS ���,a.PLM_TypeName �Ƿ��׼��,a.���һ���ջ���_�����,a.Buyer,b.��Ʒ��Ŀ����,b.��Ʒ��Ŀ����,b.��Ʒ�Ϻ�,b.��ƷƷ��
,a.���һ��POʱ��,ISNULL(a.���ϲ�����,0)���ϲ�����,ISNULL(a.��ɱ�������_�����ϲ�,0)��ɱ�������_�����ϲ�,ISNULL(a.���������_������ɱ�,0)���������_������ɱ�
,ISNULL((SELECT SUM(t.DeficienctyQtyTU) FROM #tempPurInfo t WHERE t.Code=a.Code GROUP BY t.code),0) ��;����
,ISNULL(a.����Ƿ��,0)����Ƿ��,ISNULL(a.��������,0)��������
,(SELECT t.CostStorePrice FROM #TempPrice1 t WHERE t.Code=a.Code)����
,(SELECT t.Price FROM #TempPrice2 t WHERE t.Code=a.Code)�ɹ���
FROM #tempResult a LEFT JOIN #TempTable2 b ON a.Code=b.�Ϻ�
--WHERE a.��ɱ�������_�����ϲ�>0


--SELECT * FROM dbo.v_Cust_InvInfo4OA

--SELECT * FROM #tempWh WHERE code='202010904'
--SELECT * FROM dbo.v_Cust_InvInfo4OA WHERE code='202010904' AND OrgCode='300'




