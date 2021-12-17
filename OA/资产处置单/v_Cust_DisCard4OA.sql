SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
GO

/*
�ɱ��ϵ��ʲ���ǩ
*/
ALTER VIEW v_Cust_DisCard4OA
AS
WITH data1 AS 
 (
 SELECT A1.Org,
		a3.Code OrgCode,
        A4.[Name] AS OrgName,
		A.[ID] AS [TagID] , 
        A.[Code] AS [Code] ,
		a1.ID CardID,
        A1.[DocNo] AS [AssetCard_DocNo] ,
        A1.Qty ,
        A1.[ItemCode]  ,
        A2.[AssetName]  ,
		a2.AssetDescription,--�ʲ�����		
		CASE WHEN LEFT(a1.ItemCode,'1')='5' THEN 1 ELSE 0 END IsModel,
		CASE WHEN a2.AssetDescription='���ͻ���ģ' THEN '1' ELSE '0' END IsCustomerModel,
        account.CreatePeriod,sap.DisplayName CreatePeriodName--�����ڼ�
		,dept.Name OwnerDeptName
		,dept2.Name UseDeptName
		,l.Name AssetLocationName
		,CONVERT(DECIMAL(18,2),account.OriginalValueByCreated)OriginalValueByCreated
		,CONVERT(DECIMAL(18,2),account.OriginalValue)OriginalValue--ԭֵ
		,CONVERT(DECIMAL(18,2),account.NetValueByCreated)NetValueByCreated
		,CONVERT(DECIMAL(18,2),account.NetValue)NetValue--��ֵ
		,CONVERT(DECIMAL(18,2),account.EstimateSalvageValueByCreated)EstimateSalvageValueByCreated
		,CONVERT(DECIMAL(18,2),account.EstimateSalvageValue)EstimateSalvageValue--��ֵ
		,account.AccumulateDepreciation AccumulateDepreciation2--�ۼ��۾�
		,account.AccumulateDepreciatedPeriods	--�ۼ��۾��ڼ���
		,account.AccumulateUsedPeriods--�ۼ�ʹ���ڼ���
		,account.UsedPeriodCount--ʹ�����ڼ���
		,account.UsedPeriodCount-account.AccumulateDepreciatedPeriods RemainPeriodCount
		,account.IsDepreciate
		,account.DepreciationMethodByCreated
		,account.IsOriginal
 FROM   FA_AssetTag AS A
        LEFT JOIN [FA_AssetCard] AS A1 ON ( A.[AssetCard] = A1.[ID] )
        LEFT JOIN [FA_AssetCard_Trl] AS A2 ON ( A2.SysMLFlag = 'zh-CN' )
                                              AND ( A1.[ID] = A2.[ID] )
        LEFT JOIN [Base_Organization] AS A3 ON ( A1.[Org] = A3.[ID] )
        LEFT JOIN [Base_Organization_Trl] AS A4 ON ( A4.SysMLFlag = 'zh-CN' )
                                                   AND ( A3.[ID] = A4.[ID] )
		LEFT JOIN FA_AssetCardAccountInformation account ON a.AssetCard=account.AssetCard
		LEFT JOIN dbo.Base_SOBAccountingPeriod sap ON sap.ID=account.CreatePeriod		
		LEFT JOIN dbo.CBO_Department_Trl dept ON a1.OwnerDept=dept.ID AND dept.SysMLFlag='zh-cn'
		LEFT JOIN FA_AssetTagUsageInformation tagUse ON a.ID=tagUse.AssetTag
		LEFT JOIN dbo.CBO_Department_Trl dept2 ON tagUse.UsageDept=dept2.ID AND dept2.SysMLFlag='zh-cn'
		--LEFT JOIN dbo.FA_Location l ON a.AssetLocation=l.ID
		LEFT JOIN dbo.FA_Location_Trl l ON a.AssetLocation=l.ID AND l.SysMLFlag='zh-cn'
 WHERE   A1.[Statues] = 2 --�Ѻ�׼
        AND A1.[Qty] > 0
        AND A.[Statues] = 0 --����    
AND	( account.[CurrentBusiness] = 4--��ǰҵ��4-����
                or account.[CurrentDocID] = -2 ) 
 --AND a1.DocNo='KP-30201809032' --QC-3005352   
 --AND account.IsDepreciate=1
 --AND a1.DocNo='KP-20201712006'
 --AND CONVERT(DECIMAL(18,2),account.OriginalValueByCreated)>0
 ----AND a3.Code='200'
 --AND a1.Qty>1
 --AND ISNULL(account.DepreciationMethodByCreated,0)>0
),
AccountPeriod AS
(
SELECT *,FORMAT(a.AccountPeriod_ToDate,'yyyyMM')AccountPeriod,a.ShortDate DisPlayName FROM dbo.v_Cust_SOBPeriodOA a 
WHERE a.AccountPeriod_FromDate<=DATEADD(MONTH,1,GETDATE()) AND a.AccountPeriod_ToDate>=DATEADD(month,-1,GETDATE())
),
Result AS
(
SELECT a.*,b.ShortDate,b.AccountPeriod_ToDate,b.AccountPeriod,b.DisplayName,b.ID PeroidID,b.[Year],CONVERT(INT,b.Code) [Month]
FROM data1 a,AccountPeriod b WHERE a.Org=b.Org
)
SELECT 
CONVERT(VARCHAR(100),a.TagID)+FORMAT(a.AccountPeriod_ToDate,'yyyyMM') ID ,*
,CASE WHEN a.IsDepreciate=1 AND a.IsOriginal=0 THEN 
(SELECT t.AccumualteDepreciation
FROM FA_AssetDepreciateSchedule t WHERE t.AssetCard=a.CardID
--AND t.DepreciateAccountingYear<=a.Year AND t.DepreciateAccountingPeriodNO<a.Month
AND a.Year=t.DepreciateAccountingYear AND a.Month=t.DepreciateAccountingPeriodNO
--AND t.DepreciateAccountingYear+CONVERT(VARCHAR(10),t.DepreciateAccountingPeriodNO)
)/a.Qty 
--WHEN a.IsOriginal=0 AND (a.UsedPeriodCount<DATEDIFF(MONTH,CONVERT(DATETIME,CreatePeriodName+'-01'),a.AccountPeriod_ToDate) OR ISNULL(a.DepreciationMethodByCreated,0)=0) THEN 0
--WHEN a.IsOriginal=1 AND a.UsedPeriodCount<DATEDIFF(MONTH,CONVERT(DATETIME,CreatePeriodName+'-01'),a.AccountPeriod_ToDate) OR ISNULL(a.DepreciationMethodByCreated,0)=0 THEN a.OriginalValueByCreated*0.95
WHEN a.IsOriginal=0 AND (a.UsedPeriodCount<AccumulateUsedPeriods OR ISNULL(a.DepreciationMethodByCreated,0)=0) THEN 0
WHEN a.IsOriginal=1 AND a.UsedPeriodCount<AccumulateUsedPeriods OR ISNULL(a.DepreciationMethodByCreated,0)=0 THEN a.OriginalValueByCreated*0.95
ELSE a.OriginalValueByCreated*0.95/a.UsedPeriodCount *DATEDIFF(MONTH,CONVERT(DATETIME,CreatePeriodName+'-01'),a.AccountPeriod_ToDate)/a.Qty END AccumulateDepreciation
FROM Result a
--ORDER BY a.AssetCard_DocNo,a.ShortDate
--SELECT a.*,b.ID PeroidID 
--FROM Result a LEFT JOIN dbo.v_Cust_SOBPeriodOA b ON a.DisplayName=b.ShortDate AND a.Org=b.Org

--SELECT * FROM v_cust_discard4oa



/*
�ʲ���ֵ�󱨷�
����ʹ�����ޱ��ϵ�
��ֵ������ı���
�������ϵ�
*/

GO
