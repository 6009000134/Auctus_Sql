ALTER PROC sp_Auctus_BOMDifference
(
@MasterBom1 BIGINT,
@MasterBom2 BIGINT,
@IsShowAll INT
)
AS
BEGIN
--DECLARE @Code VARCHAR(10)
--DECLARE @BomversionCode VARCHAR(20),@BomversionCode2 VARCHAR(20)

--SELECT id FROM dbo.Base_Organization WHERE code='300'
--1001708020135665
--1001811027260737
--1001905101632475
--1001708090012937
--SELECT a.ID,a.ItemMaster,a.BOMVersionCode FROM dbo.CBO_BOMMaster a INNER JOIN dbo.CBO_ItemMaster b ON a.ItemMaster=b.ID WHERE b.Code='101010004'
--AND a.Org=1001708020135665
--DECLARE @MasterBom1 BIGINT,@MasterBom2 BIGINT
--SELECT a.ID FROM dbo.CBO_BOMMaster a WHERE a.ItemMaster=@Itemmaster AND a.BOMVersion=@Bomversion1
--SELECT a.ID FROM dbo.CBO_BOMMaster a WHERE a.ItemMaster=@Itemmaster AND a.BOMVersion=@Bomversion2
IF ISNULL(@IsShowAll,0)=0
BEGIN

	;WITH data1 AS
	(
	SELECT  a.MasterBom,a.ProCode,a.ProName,a.ProSpecs,a.StartDate,a.EndDate,a.BOMVersionCode,a.ParentCode,a.ParentName,a.Code,a.Name,a.SPECS
	,dbo.F_GetEnumName('UFIDA.U9.CBO.MFG.Enums.ComponentTypeEnum',a.ComponentType,'zh-cn')ComponentType,a.ParentQty,a.UsageQty
	,dbo.F_GetEnumName('UFIDA.U9.CBO.MFG.Enums.ComponentTypeEnum',a.IssueStyle,'zh-cn')IssueStyle
	,CASE WHEN a.IsPhantomPart=0 THEN '否' WHEN a.IsPhantomPart=1 THEN '是' ELSE '' END IsPhantomPart,a.EffectiveDate ,a.DisableDate
	,a.LEVER,a.ThisUseQty
	FROM dbo.Auctus_DailyBomResult a WHERE a.MasterBom=@MasterBom1
	),
	data2 AS
	(
	SELECT  a.MasterBom,a.ProCode,a.ProName,a.ProSpecs,a.StartDate,a.EndDate,a.BOMVersionCode,a.ParentCode,a.ParentName,a.Code,a.Name,a.SPECS
	,dbo.F_GetEnumName('UFIDA.U9.CBO.MFG.Enums.ComponentTypeEnum',a.ComponentType,'zh-cn')ComponentType,a.ParentQty,a.UsageQty
	,dbo.F_GetEnumName('UFIDA.U9.CBO.MFG.Enums.ComponentTypeEnum',a.IssueStyle,'zh-cn')IssueStyle
	,CASE WHEN a.IsPhantomPart=0 THEN '否' WHEN a.IsPhantomPart=1 THEN '是' ELSE '' END IsPhantomPart,a.EffectiveDate ,a.DisableDate
	,a.LEVER,a.ThisUseQty
	FROM dbo.Auctus_DailyBomResult a WHERE a.MasterBom=@MasterBom2
	),
	Result AS
    (
	SELECT a.MasterBom,a.ProCode,a.ProName,a.ProSpecs,a.StartDate,a.EndDate,a.BOMVersionCode
	,CASE WHEN ISNULL(a.ParentCode,'')='' THEN a.ProCode ELSE a.ParentCode END ParentCode--,a.ParentName
	,CASE WHEN ISNULL(a.ParentName,'')='' THEN a.ProName ELSE a.ParentName END ParentName
	,a.Code,a.Name,a.SPECS,a.ComponentType,a.ParentQty,a.UsageQty,a.IssueStyle,a.IsPhantomPart,a.EffectiveDate,a.DisableDate,a.LEVER
	,b.MasterBom MasterBom1,b.ProCode ProCode1,b.ProName ProName1,b.ProSpecs ProSpecs1,b.StartDate StartDate1,b.EndDate EndDate1,b.BOMVersionCode BOMVersionCode1
	--,b.ParentCode,b.ParentName
	,CASE WHEN ISNULL(a.ParentCode,'')='' THEN b.ProCode ELSE b.ParentCode END ParentCode1--,b.ParentName ParentName1
	,CASE WHEN ISNULL(a.ParentName,'')='' THEN b.ProName ELSE b.ParentName END ParentName1
	,b.Code Code1,b.Name Name1,b.SPECS SPECS1,b.ComponentType ComponentType1,b.ParentQty ParentQty1,b.UsageQty UsageQty1,b.IssueStyle IssueStyle1,b.IsPhantomPart IsPhantomPart1,b.EffectiveDate EffectiveDate1,b.DisableDate DisableDate1
	,CASE WHEN ISNULL(a.MasterBom,0)=0 OR ISNULL(b.MasterBom,0)=0 --OR a.ParentQty<>b.ParentQty OR a.UsageQty<>b.UsageQty
	OR a.ThisUseQty<>b.ThisUseQty	OR a.IssueStyle<>b.IssueStyle OR a.IsPhantomPart<>b.IsPhantomPart THEN '1' ELSE '0' END IsDifferent
	FROM data1 a FULL JOIN data2 b ON a.Code=b.Code AND a.ParentCode=b.ParentCode
	)
	SELECT * FROM Result a
	WHERE a.IsDifferent='1'
	ORDER BY a.LEVER,a.ParentCode,a.Code
END 
ELSE
BEGIN
	;WITH data1 AS
	(
	SELECT  a.MasterBom,a.ProCode,a.ProName,a.ProSpecs,a.StartDate,a.EndDate,a.BOMVersionCode,a.ParentCode,a.ParentName,a.Code,a.Name,a.SPECS
	,dbo.F_GetEnumName('UFIDA.U9.CBO.MFG.Enums.ComponentTypeEnum',a.ComponentType,'zh-cn')ComponentType,a.ParentQty,a.UsageQty
	,dbo.F_GetEnumName('UFIDA.U9.CBO.MFG.Enums.ComponentTypeEnum',a.IssueStyle,'zh-cn')IssueStyle
	,CASE WHEN a.IsPhantomPart=0 THEN '否' WHEN a.IsPhantomPart=1 THEN '是' ELSE '' END IsPhantomPart,a.EffectiveDate ,a.DisableDate
	,a.LEVER,a.ThisUseQty
	FROM dbo.Auctus_DailyBomResult a WHERE a.MasterBom=@MasterBom1
	),
	data2 AS
	(
	SELECT  a.MasterBom,a.ProCode,a.ProName,a.ProSpecs,a.StartDate,a.EndDate,a.BOMVersionCode,a.ParentCode,a.ParentName,a.Code,a.Name,a.SPECS
	,dbo.F_GetEnumName('UFIDA.U9.CBO.MFG.Enums.ComponentTypeEnum',a.ComponentType,'zh-cn')ComponentType,a.ParentQty,a.UsageQty
	,dbo.F_GetEnumName('UFIDA.U9.CBO.MFG.Enums.ComponentTypeEnum',a.IssueStyle,'zh-cn')IssueStyle
	,CASE WHEN a.IsPhantomPart=0 THEN '否' WHEN a.IsPhantomPart=1 THEN '是' ELSE '' END IsPhantomPart,a.EffectiveDate ,a.DisableDate
	,a.LEVER,a.ThisUseQty
	FROM dbo.Auctus_DailyBomResult a WHERE a.MasterBom=@MasterBom2
	)
	SELECT a.MasterBom,a.ProCode,a.ProName,a.ProSpecs,a.StartDate,a.EndDate,a.BOMVersionCode
	,CASE WHEN ISNULL(a.ParentCode,'')='' THEN a.ProCode ELSE a.ParentCode END ParentCode--,a.ParentName
	,CASE WHEN ISNULL(a.ParentName,'')='' THEN a.ProName ELSE a.ParentName END ParentName
	,a.Code,a.Name,a.SPECS,a.ComponentType,a.ParentQty,a.UsageQty,a.IssueStyle,a.IsPhantomPart,a.EffectiveDate,a.DisableDate
	,b.MasterBom MasterBom1,b.ProCode ProCode1,b.ProName ProName1,b.ProSpecs ProSpecs1,b.StartDate StartDate1,b.EndDate EndDate1,b.BOMVersionCode BOMVersionCode1
	--,b.ParentCode,b.ParentName
	,CASE WHEN ISNULL(a.ParentCode,'')='' THEN b.ProCode ELSE b.ParentCode END ParentCode1--,b.ParentName ParentName1
	,CASE WHEN ISNULL(a.ParentName,'')='' THEN b.ProName ELSE b.ParentName END ParentName1
	,b.Code Code1,b.Name Name1,b.SPECS SPECS1,b.ComponentType ComponentType1,b.ParentQty ParentQty1,b.UsageQty UsageQty1,b.IssueStyle IssueStyle1,b.IsPhantomPart IsPhantomPart1,b.EffectiveDate EffectiveDate1,b.DisableDate DisableDate1
	,CASE WHEN ISNULL(a.MasterBom,0)=0 OR ISNULL(b.MasterBom,0)=0 --OR a.ParentQty<>b.ParentQty OR a.UsageQty<>b.UsageQty
	OR a.ThisUseQty<>b.ThisUseQty
	OR a.IssueStyle<>b.IssueStyle OR a.IsPhantomPart<>b.IsPhantomPart THEN '1' ELSE '0' END IsDifferent
	FROM data1 a FULL JOIN data2 b ON a.Code=b.Code AND a.ParentCode=b.ParentCode
	ORDER BY a.LEVER,a.ParentCode,a.Code
END 

END 
