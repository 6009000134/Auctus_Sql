
/*
无厂商价目表、无货源、无料品-供应商交叉、未承认料品数据
*/
ALTER PROC [dbo].[sp_Auctus_Mail_ItemMissProp]
AS

DECLARE @Org BIGINT=(SELECT id FROM dbo.Base_Organization WHERE code='300')
DECLARE @html NVARCHAR(max)=''




 IF object_id('tempdb.dbo.#tempDefineValue') is NULL
 CREATE TABLE #tempDefineValue(Code VARCHAR(50),Name NVARCHAR(255),Type VARCHAR(50))
 ELSE
 TRUNCATE TABLE #tempDefineValue
 --MRP分类值集
 INSERT INTO #tempDefineValue
         ( Code, Name, Type )
SELECT T.Code,T.Name,'MRPCategory' FROM ( SELECT  A.[ID] as [ID], A.[Code] as [Code], A1.[Name] as [Name], A.[SysVersion] as [SysVersion], A.[ID] as [MainID], A2.[Code] as SysMlFlag
 , ROW_NUMBER() OVER(ORDER BY A.[Code] asc, (A.[ID] + 17) asc ) AS rownum  FROM  Base_DefineValue as A  left join Base_Language as A2 on (A2.Code = 'zh-CN')
  and (A2.Effective_IsEffective = 1)  left join [Base_DefineValue_Trl] as A1 on (A1.SysMlFlag = 'zh-CN') and (A1.SysMlFlag = A2.Code) and (A.[ID] = A1.[ID])
   WHERE  (((((((A.[ValueSetDef] = (SELECT ID FROM Base_ValueSetDef WHERE code='MRPCategory') ) and (A.[Effective_IsEffective] = 1)) and (A.[Effective_EffectiveDate] <= GETDATE())) 
   AND (A.[Effective_DisableDate] >= GETDATE())) and (1 = 1)) and (1 = 1)) and (1 = 1))) T


IF object_id('tempdb.dbo.#tempResult') is NULL
BEGIN
	CREATE TABLE #tempResult (MID BIGINT)
END 
ELSE
BEGIN 
	TRUNCATE TABLE #tempResult
END 
INSERT INTO #tempResult
SELECT a.ID FROM dbo.CBO_ItemMaster a 
WHERE a.ItemFormAttribute=9 AND a.Org=@Org AND a.Effective_IsEffective=1  
AND (PATINDEX('1%',a.Code)>0 OR PATINDEX('2%',a.Code)>0 OR PATINDEX('3%',a.Code)>0)
AND a.CreatedOn>'2019-12-20'

--SELECT * FROM #tempResult

;
WITH PPRData AS--厂商价表
(SELECT  COUNT(b.MID)IsExistsPrice,b.MID				--倒序排生效日
				FROM    PPR_PurPriceLine a1 INNER JOIN #tempResult b ON a1.ItemInfo_ItemID=b.MID
						INNER JOIN PPR_PurPriceList a2 ON a1.PurPriceList = a2.ID AND a2.Status = 2 AND a2.Cancel_Canceled = 0 AND a1.Active = 1
				WHERE   NOT EXISTS ( SELECT 1 FROM CBO_Supplier WHERE DescFlexField_PrivateDescSeg3 IN ('OT01') AND a2.Supplier = ID ) AND 
						a2.Org = @Org
						AND a1.FromDate <= GETDATE()
						GROUP BY b.MID
)
SELECT @html=@html+'<h2>无厂商价目表料号</h2><br/><table border="1">
<tr bgcolor="#cae7fc">
		<th nowrap="nowrap" style="width:40px;">序号</th>
		<th nowrap="nowrap">MRP分类</th>
		<th nowrap="nowrap" style="width:140px;">创建时间</th>
		<th nowrap="nowrap">料号</th>
		<th nowrap="nowrap" style="width:140px;">品名</th>
		<th nowrap="nowrap" style="width:340px;">规格</th>
		<th nowrap="nowrap">开发采购</th>
		<th nowrap="nowrap">Buyer</th>
		<th nowrap="nowrap">MC责任人</th>
		</tr>'
+ISNULL(CAST(
(SELECT 
td=ROW_NUMBER() OVER(ORDER BY mrp.Name,m.Code),''
,td=ISNULL(mrp.Name,''),'',td=FORMAT(m.CreatedOn,'yyyy-MM-dd HH点'),''
,td=m.Code,''
,td=m.Name,'',td=m.SPECS,''
--,td=CASE WHEN ISNULL(q.IsExistsPrice,0)=0 THEN '否' ELSE '是' END,''
,td=ISNULL(op1.Name,''),'',td=ISNULL(op21.Name,''),'',td=ISNULL(op31.Name,'')
FROM #tempResult a INNER JOIN dbo.CBO_MrpInfo d ON a.MID=d.ItemMaster
INNER JOIN dbo.CBO_ItemMaster m ON a.MID=m.ID --AND m.ItemFormAttribute=9--采购件
LEFT JOIN PPRData q ON a.MID=q.MID--厂商价表
LEFT JOIN dbo.CBO_Operators op ON m.DescFlexField_PrivateDescSeg6=op.Code LEFT JOIN dbo.CBO_Operators_Trl op1 ON op.ID=op1.id  AND ISNULL(op1.SysMLFlag,'zh-cn')='zh-cn'
LEFT JOIN dbo.CBO_Operators op2 ON m.DescFlexField_PrivateDescSeg23=op2.Code LEFT JOIN dbo.CBO_Operators_Trl op21 ON op2.ID=op21.id  AND ISNULL(op21.SysMLFlag,'zh-cn')='zh-cn'
LEFT JOIN dbo.CBO_Operators op3 ON m.DescFlexField_PrivateDescSeg24=op3.Code LEFT JOIN dbo.CBO_Operators_Trl op31 ON op3.ID=op31.id  AND ISNULL(op31.SysMLFlag,'zh-cn')='zh-cn'
LEFT JOIN #tempDefineValue mrp ON m.DescFlexField_PrivateDescSeg22=mrp.Code
WHERE ISNULL(q.IsExistsPrice,0)=0
FOR XML PATH('tr'),type)AS NVARCHAR(MAX)),'')+'</table>'

;
WITH SupplySource AS--货源
(
SELECT DISTINCT a.ItemInfo_ItemID FROM dbo.CBO_SupplySource a INNER JOIN dbo.CBO_Supplier b ON a.SupplierInfo_Supplier=b.ID
INNER JOIN #tempResult c ON a.ItemInfo_ItemID=c.MID
WHERE b.DescFlexField_PrivateDescSeg3 NOT IN ('OT01','NEI01')
AND a.Effective_IsEffective=1
)
SELECT @html=@html+'<h2>无货源表料号</h2><br/><table border="1">
<tr bgcolor="#cae7fc">
		<th nowrap="nowrap" style="width:40px;">序号</th>
		<th nowrap="nowrap">MRP分类</th>
		<th nowrap="nowrap" style="width:140px;">创建时间</th>
		<th nowrap="nowrap">料号</th>
		<th nowrap="nowrap" style="width:140px;">品名</th>
		<th nowrap="nowrap" style="width:340px;">规格</th>		
		<th nowrap="nowrap">开发采购</th>
		<th nowrap="nowrap">Buyer</th>
		<th nowrap="nowrap">MC责任人</th>
		</tr>'
+ISNULL(CAST(
(SELECT 
td=ROW_NUMBER() OVER(ORDER BY mrp.Name,m.Code),''
,td=mrp.Name ,'',td=FORMAT(m.CreatedOn,'yyyy-MM-dd HH点'),''
,td=m.Code,'',td=m.Name,'',td=m.SPECS,''
--,CASE WHEN ISNULL(p.ItemInfo_ItemID,'')='' THEN '否' ELSE '是' END IsSupplySource
,td=op1.Name ,'',td=op21.Name ,'',td=op31.Name
FROM #tempResult a INNER JOIN dbo.CBO_MrpInfo d ON a.MID=d.ItemMaster
INNER JOIN dbo.CBO_ItemMaster m ON a.MID=m.ID --AND m.ItemFormAttribute=9--采购件
LEFT JOIN SupplySource p ON a.MID=p.ItemInfo_ItemID--货源表
LEFT JOIN dbo.CBO_Operators op ON m.DescFlexField_PrivateDescSeg6=op.Code LEFT JOIN dbo.CBO_Operators_Trl op1 ON op.ID=op1.id  AND ISNULL(op1.SysMLFlag,'zh-cn')='zh-cn'
LEFT JOIN dbo.CBO_Operators op2 ON m.DescFlexField_PrivateDescSeg23=op2.Code LEFT JOIN dbo.CBO_Operators_Trl op21 ON op2.ID=op21.id  AND ISNULL(op21.SysMLFlag,'zh-cn')='zh-cn'
LEFT JOIN dbo.CBO_Operators op3 ON m.DescFlexField_PrivateDescSeg24=op3.Code LEFT JOIN dbo.CBO_Operators_Trl op31 ON op3.ID=op31.id  AND ISNULL(op31.SysMLFlag,'zh-cn')='zh-cn'
LEFT JOIN #tempDefineValue mrp ON m.DescFlexField_PrivateDescSeg22=mrp.Code
WHERE ISNULL(p.ItemInfo_ItemID,'')='' 
FOR XML PATH('tr'),TYPE) AS NVARCHAR(MAX)),'')+'</table>'


;
WITH ItemSupplier AS--供应商料品交叉
(
SELECT t.ItemInfo_ItemID,t.IsRecognize FROM 
(SELECT a.ItemInfo_ItemID,a.DescFlexField_PrivateDescSeg1 IsRecognize,ROW_NUMBER() OVER(PARTITION BY a.ItemInfo_ItemID ORDER BY a.DescFlexField_PrivateDescSeg1 DESC)RN
FROM dbo.CBO_SupplierItem a INNER JOIN dbo.CBO_Supplier b ON a.SupplierInfo_Supplier=b.ID
INNER JOIN #tempResult c ON a.ItemInfo_ItemID=c.MID
WHERE b.DescFlexField_PrivateDescSeg3 NOT IN ('OT01')
AND a.Effective_IsEffective=1
) t WHERE t.rn=1
)
SELECT @html=@html+'<h2>无料品供应商交叉/未承认 料号</h2><br/><table border="1">
<tr bgcolor="#cae7fc">
		<th nowrap="nowrap" style="width:40px;">序号</th>
		<th nowrap="nowrap">MRP分类</th>
		<th nowrap="nowrap" style="width:140px;">创建时间</th>
		<th nowrap="nowrap">料号</th>
		<th nowrap="nowrap" style="width:140px;">品名</th>
		<th nowrap="nowrap" style="width:340px;">规格</th>		
		<th nowrap="nowrap">是否承认</th>
		<th nowrap="nowrap">是否有交叉表</th>
		<th nowrap="nowrap">开发采购</th>
		<th nowrap="nowrap">Buyer</th>
		<th nowrap="nowrap">MC责任人</th>
		</tr>'
+ISNULL(CAST(
(SELECT 
td=ROW_NUMBER() OVER(ORDER BY mrp.Name,m.Code),''
,td=mrp.Name ,'',td=FORMAT(m.CreatedOn,'yyyy-MM-dd HH点'),''
,td=m.Code,'',td=m.Name,'',td=m.SPECS,''
,td=CASE WHEN ISNULL(o.IsRecognize,'')='True' THEN '是' ELSE '否' END ,''
,td=CASE WHEN ISNULL(o.IsRecognize,'')='' THEN '否' ELSE '是' END ,''
,td=op1.Name ,'',td=op21.Name ,'',td=op31.Name
FROM #tempResult a INNER JOIN dbo.CBO_MrpInfo d ON a.MID=d.ItemMaster
INNER JOIN dbo.CBO_ItemMaster m ON a.MID=m.ID --AND m.ItemFormAttribute=9--采购件
LEFT JOIN ItemSupplier o ON a.MID=o.ItemInfo_ItemID--供应商料品交叉
LEFT JOIN dbo.CBO_Operators op ON m.DescFlexField_PrivateDescSeg6=op.Code LEFT JOIN dbo.CBO_Operators_Trl op1 ON op.ID=op1.id  AND ISNULL(op1.SysMLFlag,'zh-cn')='zh-cn'
LEFT JOIN dbo.CBO_Operators op2 ON m.DescFlexField_PrivateDescSeg23=op2.Code LEFT JOIN dbo.CBO_Operators_Trl op21 ON op2.ID=op21.id  AND ISNULL(op21.SysMLFlag,'zh-cn')='zh-cn'
LEFT JOIN dbo.CBO_Operators op3 ON m.DescFlexField_PrivateDescSeg24=op3.Code LEFT JOIN dbo.CBO_Operators_Trl op31 ON op3.ID=op31.id  AND ISNULL(op31.SysMLFlag,'zh-cn')='zh-cn'
LEFT JOIN #tempDefineValue mrp ON m.DescFlexField_PrivateDescSeg22=mrp.Code
WHERE ISNULL(o.IsRecognize,'')<>'True' OR ISNULL(o.IsRecognize,'')=''
FOR XML PATH('tr'),TYPE) AS NVARCHAR(MAX)),'') +'</table>'
declare @strbody varchar(3000)
declare @style Varchar(2000)
--SET @style=	'<style>table,table tr th, table tr td { border:2px solid #cecece; } table {text-align: center; border-collapse: collapse; padding:2px;}</style>'
SET @style='<style>table,table tr th, table tr td { border:2px solid #cecece; }table {text-align: center;border-collapse: collapse; padding:2px;word-break: break-all;table-layout:fixed;}table tr th{width:100px;}table tr td{width:100px;}</style>'
set @strbody=@style+N'<H2>U9新料提示，请维护基础数据</H2>
1.请研发及时释放图纸/规格书</br>
2.请TQC及时维护交叉表</br>
3.请采购开发及时维护货源表，厂商价目表'
set @html=@strbody+@html+N'</br><H2>以上由系统发出无需回复!</H2>'

	EXEC msdb.dbo.sp_send_dbmail 
		@profile_name=db_Automail, 
		@recipients='zougl@auctus.cn;perla_yu@auctus.cn;huangxh@auctus.cn', 
		--@recipients='liufei@auctus.com;', 
		--@copy_recipients='zougl@auctus.cn;hudz@auctus.cn;',
		@blind_copy_recipients='liufei@auctus.com',
		--@recipients='liufei@auctus.cn;', 
		--@copy_recipients='zougl@auctus.cn;hudz@auctus.cn;', 
		@subject ='无厂商价目表、无货源、无料品-供应商交叉、未承认料品数据',
		@body = @html,
		@body_format = 'HTML'; 