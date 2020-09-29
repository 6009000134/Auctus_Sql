/*
¼ÇÕËÆÚ¼ä
*/
ALTER  VIEW v_Cust_SOBPeriodOA
as
SELECT  *,FORMAT(AccountPeriod_FromDate,'yyyy-MM-')
+SUBSTRING(FORMAT(GETDATE(),'yyyyMMdd'),7,2)
NowDate
,FORMAT(t.Year,'#')+'-'+t.Code ShortDate
FROM    ( SELECT    A.[ID] AS [ID] ,
                    A.[Year] AS [Year] ,
                    A.[Code] AS [Code] ,
                    A.[Number] AS [Number] ,
                    A1.[FromDate] AS [AccountPeriod_FromDate] ,
                    A1.[ToDate] AS [AccountPeriod_ToDate] ,
                    A.[SysVersion] AS [SysVersion] ,
					a2.Org,o.Code OrgCode,o1.Name OrgName,
                    ROW_NUMBER() OVER ( ORDER BY org,A.[Year] ASC, A.[Number] ASC, ( A.[ID]
                                                              + 17 ) ASC ) AS rownum
          FROM      Base_SOBAccountingPeriod AS A
                    LEFT JOIN [Base_AccountingPeriod] AS A1 ON ( A.[AccountPeriod] = A1.[ID] )
                    LEFT JOIN [Base_SetofBooks] AS A2 ON ( A.[SetofBooks] = A2.[ID] )
					LEFT JOIN dbo.Base_Organization o ON a2.Org=o.ID
					LEFT JOIN dbo.Base_Organization_Trl o1 ON a2.Org=o1.ID AND o1.SysMLFlag='zh-cn'
					WHERE a2.SOBType=0
        ) T
		
    



GO



