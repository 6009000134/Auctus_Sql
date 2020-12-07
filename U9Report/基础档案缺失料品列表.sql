
/*
300组织：无MRP分类、无Buyer、无MC责任人料号信息
*/
--EXEC sp_Auctus_Mail_BasicDataMaintain
ALTER  PROC [dbo].[sp_Auctus_Mail_BasicDataMaintain]
AS
BEGIN
	DECLARE @Org BIGINT=(SELECT id FROM dbo.Base_Organization WHERE code='300')
	IF EXISTS(	SELECT 1	FROM dbo.CBO_ItemMaster a	WHERE a.Org=@Org
	AND a.Effective_IsEffective=1
	--AND (	PATINDEX('1%',a.Code)>0	OR PATINDEX('2%',a.Code)>0	OR PATINDEX('3%',a.Code)>0	) 
	AND a.ItemFormAttribute IN (9,10)--制造件、采购件
	AND (ISNULL(a.DescFlexField_PrivateDescSeg22,'')=''	OR ISNULL(a.DescFlexField_PrivateDescSeg23,'')=''	OR ISNULL(a.DescFlexField_PrivateDescSeg24,'')='')	)
	BEGIN
		
		 --料品扩展字段的值集
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
		   AND (A.[Effective_DisableDate] >= GETDATE())) and (1 = 1)) and (1 = 1)) and (1 = 1))) T WHERE T.rownum>  0 and T.rownum<= 130
		
		IF NOT EXISTS (SELECT 1
		FROM dbo.CBO_ItemMaster a
		LEFT JOIN dbo.CBO_Operators op ON a.DescFlexField_PrivateDescSeg23=op.Code LEFT JOIN dbo.CBO_Operators_Trl op1 ON op.ID=op1.ID AND ISNULL(op1.SysMLFlag,'zh-cn')='zh-cn'
		LEFT JOIN dbo.CBO_Operators op2 ON a.DescFlexField_PrivateDescSeg24=op2.Code LEFT JOIN dbo.CBO_Operators_Trl op21 ON op2.ID=op21.ID AND ISNULL(op21.SysMLFlag,'zh-cn')='zh-cn'
		LEFT JOIN #tempDefineValue t ON a.DescFlexField_PrivateDescSeg22=t.Code
		WHERE a.Org=@Org
		AND a.Effective_IsEffective=1
		AND (
		PATINDEX('1%',a.Code)>0
		OR PATINDEX('2%',a.Code)>0
		OR PATINDEX('3%',a.Code)>0
		) AND (ISNULL(a.DescFlexField_PrivateDescSeg22,'')=''
		OR ISNULL(a.DescFlexField_PrivateDescSeg23,'')=''
		OR ISNULL(a.DescFlexField_PrivateDescSeg24,'')='')	)
		BEGIN
			RETURN 
		END 


		--基础数据缺失结果集合
		DECLARE @html NVARCHAR(max)=''
		SET @html=@html+'<table border="1">'
		SET @html=@html+'<tr bgcolor="#cae7fc">
		<th nowrap="nowrap">料号</th>
		<th nowrap="nowrap">品名</th>
		<th nowrap="nowrap">规格</th>
		<th nowrap="nowrap">MRP分类</th>
		<th nowrap="nowrap">执行采购</th>
		<th nowrap="nowrap">MC责任人</th>
		<th nowrap="nowrap">料品形态属性</th>
		</tr>'
		SET @html=@html+
		CAST((SELECT 
		td=a.Code,'',td=a.Name,'',td=a.SPECS--,'',td=a.DescFlexField_PrivateDescSeg6
		,'',td=ISNULL(t.Name,'')
		,'',td=ISNULL(op1.Name,'') ,'',td=ISNULL(op21.Name,'') 
		,'',td=dbo.F_GetEnumName('UFIDA.U9.CBO.SCM.Item.ItemTypeAttributeEnum',a.ItemFormAttribute,'zh-cn')
		FROM dbo.CBO_ItemMaster a
		LEFT JOIN dbo.CBO_Operators op ON a.DescFlexField_PrivateDescSeg23=op.Code LEFT JOIN dbo.CBO_Operators_Trl op1 ON op.ID=op1.ID AND ISNULL(op1.SysMLFlag,'zh-cn')='zh-cn'
		LEFT JOIN dbo.CBO_Operators op2 ON a.DescFlexField_PrivateDescSeg24=op2.Code LEFT JOIN dbo.CBO_Operators_Trl op21 ON op2.ID=op21.ID AND ISNULL(op21.SysMLFlag,'zh-cn')='zh-cn'
		LEFT JOIN #tempDefineValue t ON a.DescFlexField_PrivateDescSeg22=t.Code
		WHERE a.Org=@Org
		AND a.Effective_IsEffective=1
		AND (
		PATINDEX('1%',a.Code)>0
		OR PATINDEX('2%',a.Code)>0
		OR PATINDEX('3%',a.Code)>0
		) AND (ISNULL(a.DescFlexField_PrivateDescSeg22,'')=''
		OR ISNULL(a.DescFlexField_PrivateDescSeg23,'')=''
		OR ISNULL(a.DescFlexField_PrivateDescSeg24,'')='')		
		ORDER BY a.Code FOR XML PATH('tr'),type)AS nvarchar(MAX))
		SET @html=@html+'</table>'
		DECLARE @style NVARCHAR(MAX)
		DECLARE @strbody NVARCHAR(MAX)
		SET @style=	'<style>table,table tr th, table tr td { border:2px solid #cecece; } table {text-align: center; border-collapse: collapse; padding:2px;}</style>'
		SET @strbody=@style+N'<H2>Dear All,</H2><H2></br>&nbsp;&nbsp;以下是制造件和采购件中无MRP分类或无执行采购或无MC责任人料品数据，请相关人员知悉。谢谢！</H2>'
		SET @html=@strbody+@html+N'</br><H2>以上由系统发出无需回复!</H2>'
		
		EXEC msdb.dbo.sp_send_dbmail 
		@profile_name=db_Automail, 
		@recipients='huangxh@auctus.cn;heqh@auctus.cn;lisd@auctus.cn;', 
		--@recipients='liufei@auctus.com;', 
		--@copy_recipients='zougl@auctus.cn;hudz@auctus.cn;',
		@blind_copy_recipients='liufei@auctus.com',
		@subject ='无MRP分类、无执行采购、无MC责任人料品列表',
		@body = @html,
		@body_format = 'HTML'; 
	END 
	

END 