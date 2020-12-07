
BEGIN
DECLARE @html NVARCHAR(MAX)=''
DECLARE @Date DATE
DECLARE @Date7 DATE
DECLARE @Date3 DATE
DECLARE @Date15 DATE
DECLARE @Date21 DATE
DECLARE @Date56 DATE
SET @Date='2019-11-14'
SET @Date7=DATEADD(DAY,7,'2019-11-14') --7天齐套预警
SET @Date3=DATEADD(DAY,3,'2019-11-14') --3天齐套预警
SET @Date15=DATEADD(DAY,15,'2019-11-14')--15天齐套预警
SET @Date21=DATEADD(DAY,21,'2019-11-14')--21天齐套预警
SET @Date56=DATEADD(DAY,56,'2019-11-14')--15天齐套预警
--8周起始日期天汇总列表
DECLARE @SD1 DATE,@ED1 DATE
SET @SD1=DATEADD(DAY,2+(-1)*DATEPART(WEEKDAY,'2019-11-14'),'2019-11-14')
SET @ED1=DATEADD(DAY,7,@SD1)
SET @Date56=DATEADD(DAY,56,@SD1)--15天齐套预警

--料品扩展字段的值集
 IF object_id('tempdb.dbo.#tempMRPCategory') is NULL
 CREATE TABLE #tempMRPCategory(Code VARCHAR(50),Name NVARCHAR(255),Type VARCHAR(50))
 ELSE
 TRUNCATE TABLE #tempMRPCategory
 --MRP分类值集
 INSERT INTO #tempMRPCategory
         ( Code, Name, Type )
SELECT T.Code,T.Name,'MRPCategory' FROM ( SELECT  A.[ID] as [ID], A.[Code] as [Code], A1.[Name] as [Name], A.[SysVersion] as [SysVersion], A.[ID] as [MainID], A2.[Code] as SysMlFlag
 , ROW_NUMBER() OVER(ORDER BY A.[Code] asc, (A.[ID] + 17) asc ) AS rownum  FROM  Base_DefineValue as A  left join Base_Language as A2 on (A2.Code = 'zh-CN')
  and (A2.Effective_IsEffective = 1)  left join [Base_DefineValue_Trl] as A1 on (A1.SysMlFlag = 'zh-CN') and (A1.SysMlFlag = A2.Code) and (A.[ID] = A1.[ID])
   WHERE  (((((((A.[ValueSetDef] = (SELECT ID FROM Base_ValueSetDef WHERE code='MRPCategory') ) and (A.[Effective_IsEffective] = 1)) and (A.[Effective_EffectiveDate] <= '2019-11-14')) 
   AND (A.[Effective_DisableDate] >= '2019-11-14')) and (1 = 1)) and (1 = 1)) and (1 = 1))) T



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
DescFlexField_PrivateDescSeg19 NVARCHAR(300),--客户产品名称
DescFlexField_PrivateDescSeg20 NVARCHAR(300),--项目编码
DescFlexField_PrivateDescSeg21 NVARCHAR(300),--项目代号
DescFlexField_PrivateDescSeg23 NVARCHAR(300),--执行采购员
MRPCode VARCHAR(50),--MRP分类
MRPCategory NVARCHAR(300),--MRP分类
Buyer NVARCHAR(20),--执行采购分类
MCCode VARCHAR(20),--MC负责人编码
MCName NVARCHAR(20),--MC负责人
FixedLT DECIMAL(18,0),--固定提前期
ProductLine NVARCHAR(255)--产品系列
)
--ELSE
--TRUNCATE TABLE #tempTable

--INSERT INTO #tempTable EXEC sp_Auctus_AllSetCheckWithDemandCode2 1001708020135665,'','','',@Date56,'1','1','0'

----取每天7点备份的8周齐套数据
--INSERT INTO #tempTable 
--SELECT
--DocNo ,
--DocLineNo ,
--PickLineNo ,
--DocType ,
--ProductID ,
--ProductCode ,
--ProductName ,
--ProductSPECS ,
--ProductQty ,
--DemandCode ,
--ItemMaster ,
--Code ,
--Name ,
--SPEC ,
--SafetyStockQty ,
--IssuedQty ,
--STDReqQty ,
--ActualReqQty ,
--ReqQty ,
--ActualReqDate ,
--RN ,
--DemandCode2 ,
--LackAmount ,
--IsLack ,
--WhavailiableAmount ,
--PRList ,
--PRApprovedQty ,
--PRFlag ,
--POList ,
--POReqQtyTu ,
--RCVList ,
--ArriveQtyTU ,
--RcvQtyTU ,
--RcvFlag ,
--ResultFlag ,
--DescFlexField_PrivateDescSeg19 ,--客户产品名称
--DescFlexField_PrivateDescSeg20 ,--项目编码
--DescFlexField_PrivateDescSeg21 ,--项目代号
--DescFlexField_PrivateDescSeg23 ,--执行采购员
--MRPCode ,--MRP分类
--MRPCategory ,--MRP分类
--Buyer ,--执行采购分类
--MCCode,--MC负责人编码
--MCName,--MC负责人
--FixedLT ,--固定提前期
--ProductLine --产品系列
--FROM dbo.Auctus_FullSetCheckResult8 
--WHERE CopyDate>CONVERT(DATE,@Date)




----工单的实际需求时间=实际需求时间-原材料采购后处理期
----委外WPO实际需求时间=实际需求时间-采购组件采购前处理提前期-原材料采购后处理期
--UPDATE #tempTable 
--SET ActualReqDate=CASE WHEN #tempTable.DocNo LIKE'WPO%' THEN  DATEADD(DAY,(ISNULL(a.PurBackwardProcessLT,0)+ISNULL(b.PurForwardProcessLT,0))*(-1),ActualReqDate)
--ELSE DATEADD(DAY,(ISNULL(a.PurBackwardProcessLT,0))*(-1),ActualReqDate) END 
--FROM CBO_MrpInfo a,dbo.CBO_MrpInfo b WHERE a.ItemMaster=#tempTable.ItemMaster AND b.ItemMaster=#tempTable.ProductID


--安全库存欠交数量
--;
--WITH data1 AS
--(
--SELECT a.Code,MIN(a.SafetyStockQty)SafetyStockQty,MAX(a.RN)RN,MIN(a.WhavailiableAmount)WhavailiableAmount FROM #tempTable a
--WHERE a.ActualReqDate<@SD1  AND a.SafetyStockQty>0
--GROUP BY a.Code
--)
--SELECT a.Code
--,CASE WHEN a.WhavailiableAmount<0 THEN a.SafetyStockQty
--WHEN a.WhavailiableAmount>a.SafetyStockQty THEN 0
--ELSE a.SafetyStockQty-a.WhavailiableAmount END SafeQtyLack INTO #tempLackSafe
--FROM data1 a

--8周汇总列表
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
,a.MRPCategory,a.Buyer,a.MCName,a.Code,a.Name,a.SPEC,a.LackAmount
FROM #tempTable a 
),
data2 AS--行专列 汇总每周的欠料数量
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
--INTO #tempW8 
FROM data2  a LEFT JOIN data3 b ON a.Code=b.Code

SELECT @html=@html+N'<H2 bgcolor="#7CFC00">8周未齐套单据汇总列表<span style="color:red;">（不欠料为0）</span></H2>'
+N'<div style="width:1920px;overflow-x:scroll;"><table border="1">'
+N'<tr bgcolor="#cae7fc">
<th >MRP分类</th><th>Buyer</th><th >MC责任人</th>
<th >料号</th><th >品名</th><th style="width:250px;">规格</th>
<th >逾期欠料</th>
<th style="width:110px;">安全库存欠料</th>
<th style="width:115px;">'+RIGHT(CONVERT(VARCHAR(20),@SD1),5)+'~'+RIGHT(CONVERT(VARCHAR(20),DATEADD(DAY,-1,@ED1)),5)+'</th>
<th style="width:115px;">'+RIGHT(CONVERT(VARCHAR(20),DATEADD(DAY,7,@SD1)),5)+'~'+RIGHT(CONVERT(VARCHAR(20),DATEADD(DAY,-1,DATEADD(DAY,7,@ED1))),5)+'</th>
<th style="width:115px;">'+RIGHT(CONVERT(VARCHAR(20),DATEADD(DAY,14,@SD1)),5)+'~'+RIGHT(CONVERT(VARCHAR(20),DATEADD(DAY,-1,DATEADD(DAY,14,@ED1))),5)+'</th>
<th style="width:115px;">'+RIGHT(CONVERT(VARCHAR(20),DATEADD(DAY,21,@SD1)),5)+'~'+RIGHT(CONVERT(VARCHAR(20),DATEADD(DAY,-1,DATEADD(DAY,21,@ED1))),5)+'</th>
<th style="width:115px;">'+RIGHT(CONVERT(VARCHAR(20),DATEADD(DAY,28,@SD1)),5)+'~'+RIGHT(CONVERT(VARCHAR(20),DATEADD(DAY,-1,DATEADD(DAY,28,@ED1))),5)+'</th>
<th style="width:115px;">'+RIGHT(CONVERT(VARCHAR(20),DATEADD(DAY,35,@SD1)),5)+'~'+RIGHT(CONVERT(VARCHAR(20),DATEADD(DAY,-1,DATEADD(DAY,35,@ED1))),5)+'</th>
<th style="width:115px;">'+RIGHT(CONVERT(VARCHAR(20),DATEADD(DAY,42,@SD1)),5)+'~'+RIGHT(CONVERT(VARCHAR(20),DATEADD(DAY,-1,DATEADD(DAY,42,@ED1))),5)+'</th>
<th style="width:115px;">'+RIGHT(CONVERT(VARCHAR(20),DATEADD(DAY,49,@SD1)),5)+'~'+RIGHT(CONVERT(VARCHAR(20),DATEADD(DAY,-1,DATEADD(DAY,49,@ED1))),5)+'</th>
<th style="width:100px;">8周欠料数量</th>
<th style="width:90px;">库存现有量</th>
</tr>'
+CAST(( SELECT td=ISNULL(a.MRPCategory,''),'',td=ISNULL(a.Buyer,''),'',td=ISNULL(a.MCName,''),'',td=a.Code,'',td=a.Name,'',td=a.SPEC,''
,td=CASE WHEN ISNULL(a.w0,0)>0 THEN 0 ELSE ISNULL(a.w0,0)*(-1) END ,''
--,td=CASE WHEN ISNULL(a.SafeQty,0)>0 THEN 0 ELSE ISNULL(a.SafeQty,0)*(-1)END ,''
,td=ISNULL(b.SafeQtyLack,0),''
,td=CASE WHEN ISNULL(a.w1,0)>0 THEN 0 ELSE ISNULL(a.w1,0)*(-1) END ,''
--,td=CASE WHEN ISNULL(a.w1,0)>0 THEN 0 ELSE ISNULL(a.w1,0)*(-1) END ,''
,td=CASE WHEN ISNULL(a.w2,0)>0 THEN 0 ELSE ISNULL(a.w2,0)*(-1) END ,''
,td=CASE WHEN ISNULL(a.w3,0)>0 THEN 0 ELSE ISNULL(a.w3,0)*(-1) END ,''
,td=CASE WHEN ISNULL(a.w4,0)>0 THEN 0 ELSE ISNULL(a.w4,0)*(-1) END ,''
,td=CASE WHEN ISNULL(a.w5,0)>0 THEN 0 ELSE ISNULL(a.w5,0)*(-1) END ,''
,td=CASE WHEN ISNULL(a.w6,0)>0 THEN 0 ELSE ISNULL(a.w6,0)*(-1) END ,''
,td=CASE WHEN ISNULL(a.w7,0)>0 THEN 0 ELSE ISNULL(a.w7,0)*(-1) END ,''
,td=CASE WHEN ISNULL(a.w8,0)>0 THEN 0 ELSE ISNULL(a.w8,0)*(-1) END ,''
--,td=a.WhAvailiableAmount*(-1)+a.SafetyStockQty,''
,td=a.WhAvailiableAmount*(-1),''
,td=a.WhQty
FROM #tempW8 a LEFT JOIN #tempLackSafe b ON a.Code=b.Code
WHERE a.WhAvailiableAmount<0
ORDER BY ISNULL(a.w0,0),ISNULL(a.w1,0),ISNULL(a.w2,0),ISNULL(a.w3,0),ISNULL(a.w4,0),ISNULL(a.w5,0),ISNULL(a.w6,0),ISNULL(a.w7,0),ISNULL(a.w8,0),a.code FOR XML PATH('tr'),TYPE)AS nvarchar(MAX))+N'</table><br/></div>'


declare @strbody varchar(800)
declare @style Varchar(2000)
--SET @style=	'<style>table,table tr th, table tr td { border:2px solid #cecece; } table {text-align: center; border-collapse: collapse; padding:2px;}</style>'
SET @style=	'<style>table,table tr th, table tr td { border:2px solid #cecece; }table {text-align: center;border-collapse: collapse; padding:2px;word-break: break-all;table-layout:fixed;}table tr th{width:80px;}table tr td{width:80px;}</style>'
set @strbody=@style+N'<H2>Dear All,</H2><H2></br>&nbsp;&nbsp;以下是截止'+convert(varchar(19),@Date56,120)+'（不包含'+convert(varchar(19),@Date56,120)+'）的工单齐套数据，请相关人员知悉。谢谢！</H2>'
set @html=@strbody+@html+N'</br><H2>以上由系统发出无需回复!</H2>'

SELECT @html

 EXEC msdb.dbo.sp_send_dbmail 
	@profile_name=db_Automail, 
	@blind_copy_recipients='liufei@auctus.com',
	--@recipients='liufei@auctus.cn;', 
	--@copy_recipients='zougl@auctus.cn;hudz@auctus.cn;', 
	@subject ='未齐套单据汇总列表（8周）',
	@body = @html,
	@body_format = 'HTML'; 
	



END 