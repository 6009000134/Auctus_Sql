/*
校验下发组织中是否存在该料号和供应商
*/
ALTER PROC sp_Auctus_SV_CheckSupplyInfo
(
@Code VARCHAR(500),
@Orgs VARCHAR(500),
@SupplierIDs VARCHAR(2000),
@OrderNos VARCHAR(100),
@Result VARCHAR(2000) OUT
)
AS
BEGIN
	--DECLARE @Code VARCHAR(500)='335080289',
	--		@Orgs VARCHAR(500)='1001708020135665,1001708020135435',
	--		@SupplierIDs VARCHAR(2000)='1001912110012489,1001812281884554,1002004140153094',
	--		@Result VARCHAR(2000)='1'
	--校验下发组织是否存在料号@Code
		--校验下发组织是否存在料号@Code
	IF	EXISTS(
	SELECT 1
	FROM dbo.Base_Organization a  LEFT JOIN dbo.CBO_ItemMaster b ON a.ID=b.Org AND b.Code=@Code
	WHERE a.ID IN (SELECT strID FROM dbo.fun_Cust_StrToTable(@Orgs))
	AND ISNULL(b.ID,0)=0
	)
	BEGIN--下发组织不存在料号@Code
		SET @Result=(
		SELECT a.Code+','
		FROM dbo.Base_Organization a  LEFT JOIN dbo.CBO_ItemMaster b ON a.ID=b.Org AND b.Code=@Code
		WHERE a.ID IN (SELECT strID FROM dbo.fun_Cust_StrToTable(@Orgs))
		AND ISNULL(b.ID,0)=0
		FOR XML PATH(''))		
		SET @Result=SUBSTRING(@Result,1,LEN(@Result)-1)+'组织下不存在料号'+@Code
	END 
	ELSE--下发组织存在料号
    BEGIN
		--料号的配额比例方式要一致
		IF	(
		SELECT COUNT(1) FROM (
		SELECT DISTINCT b.PurchaseQuotaMode FROM dbo.CBO_ItemMaster a LEFT JOIN dbo.CBO_PurchaseInfo b ON a.ID=b.ItemMaster
		WHERE a.Code=@Code  AND a.Org IN (SELECT strID FROM dbo.fun_Cust_StrToTable(@Orgs))
		)t )>1
		BEGIN
			SET @Result='下发的组织中料品的配额方式不一致！'
			RETURN;
		END 
		
		--供应商总数
		DECLARE @sc INT=(SELECT COUNT(1) FROM dbo.fun_Cust_StrToTable(@SupplierIDs))
		DECLARE @IsSupplyOk VARCHAR(2000)=''
		IF OBJECT_ID(N'tempdb.dbo.#tempSupplier',N'U') IS NULL
		BEGIN
			CREATE TABLE #tempSupplier
			(
			ID BIGINT,
			Code VARCHAR(50),
			Name NVARCHAR(300)
			)
		END 
		ELSE
        BEGIN
			TRUNCATE TABLE #tempSupplier
		END 
		INSERT INTO #tempSupplier
		        ( ID, Code, Name )
				  SELECT a.ID,a.Code,b.Name FROM dbo.CBO_Supplier a INNER JOIN dbo.CBO_Supplier_Trl b ON a.ID=b.ID AND ISNULL(b.SysMLFlag,'zh-cn')='zh-cn'
		WHERE a.ID IN (SELECT strID FROM dbo.fun_Cust_StrToTable(@SupplierIDs))
		;
		WITH Orgs AS
		(SELECT a.ID,a.Code FROM dbo.Base_Organization a WHERE a.ID IN (SELECT strID FROM dbo.fun_Cust_StrToTable(@Orgs))
		),
		SupplyInfo AS
        (
		SELECT a.ID,a.Org,b.Name
		FROM dbo.CBO_Supplier a INNER JOIN dbo.CBO_Supplier_Trl b ON a.ID=b.ID AND ISNULL(b.SysMLFlag,'zh-cn')='zh-cn'
		WHERE b.Name IN (SELECT Name FROM #tempSupplier)
		)
		SELECT @IsSupplyOk =(		
		SELECT t.Code+'组织下供应商只有'+CONVERT(VARCHAR(4),COUNT(t.Code))+'家,'
		FROM 
		(SELECT DISTINCT a.ID,a.Code,b.Name FROM Orgs a INNER JOIN SupplyInfo b ON a.ID=b.Org) t
		GROUP BY t.ID,t.Code
		HAVING COUNT(t.ID)<@sc
		FOR XML PATH(''))
		IF	ISNULL(@IsSupplyOk,'')!=''--不存在组织
		BEGIN
			SET @Result=@IsSupplyOk
			SET @Result=SUBSTRING(@Result,1,LEN(@Result)-1)
		END 
		ELSE
        BEGIN--存在组织料号，判断供货顺序和配额比例是否正常:新逻辑
			IF EXISTS(
			SELECT 1 FROM dbo.CBO_SupplySource a INNER JOIN dbo.CBO_Supplier b ON a.SupplierInfo_Supplier=b.ID
			LEFT JOIN dbo.CBO_Supplier_Trl b1 ON b.ID=b1.ID AND ISNULL(b1.SysMLFlag,'zh-cn')='zh-cn'
			WHERE a.ItemInfo_ItemCode=@Code AND  b1.Name NOT IN(SELECT Name FROM #tempSupplier) AND a.Org IN (SELECT strID FROM dbo.fun_Cust_StrToTable(@Orgs))
			AND a.OrderNO IN (SELECT strID FROM dbo.fun_Cust_StrToTable(@OrderNos))
			)
			BEGIN--存在要失效的货源信息
				IF (SELECT DISTINCT b.PurchaseQuotaMode FROM dbo.CBO_ItemMaster a INNER JOIN dbo.CBO_PurchaseInfo b ON a.ID=b.ItemMaster AND a.Code=@Code AND a.Org IN (SELECT strID FROM dbo.fun_Cust_StrToTable(@Orgs))) IN (0,1)
				BEGIN--判断要失效的货源信息是否与现有供货顺序重复										
				SET @Result=
					(SELECT o1.Name+'中现有货源：'+b1.Name+'的供货顺序'+CONVERT(VARCHAR(10),a.OrderNO)+'与当前供货顺序重复' FROM dbo.CBO_SupplySource a INNER JOIN dbo.CBO_Supplier b ON a.SupplierInfo_Supplier=b.ID
					LEFT JOIN dbo.CBO_Supplier_Trl b1 ON b.ID=b1.ID AND ISNULL(b1.SysMLFlag,'zh-cn')='zh-cn'
					LEFT JOIN dbo.Base_Organization o ON a.Org=o.ID LEFT JOIN dbo.Base_Organization_Trl o1 ON o.ID=o1.ID AND ISNULL(o1.SysMLFlag,'zh-cn')='zh-cn'
					WHERE a.ItemInfo_ItemCode=@Code AND  b1.Name NOT IN(SELECT Name FROM #tempSupplier) AND a.Org IN (SELECT strID FROM dbo.fun_Cust_StrToTable(@Orgs)))
				END 
				ELSE
                BEGIN
					SET @Result='1'
				END 
			END
			ELSE
            BEGIN
				SET @Result='1'
			END 			
		END 		
	END 
END 

