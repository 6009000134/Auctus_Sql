alter VIEW v_Cust_PO4OA
as
SELECT  a.ID ,
        a.DocNo ,
        FORMAT(a.BusinessDate,'yyyy-MM-dd') BusinessDate,
        a.Org ,
        o.Code OrgCode ,
        o1.Name OrgName ,
        a.Supplier_Supplier SupplierID ,
		s.Code SupplierCode,
		s1.Name SupplierName,
        a.Status ,
        dbo.F_GetEnumName('UFIDA.U9.PM.PO.PODOCStatusEnum', a.Status, 'zh-cn') StatusName,
		a.FC CurrencyID,
		cur.Code CurrencyCode,
		cur1.Name CurrencyName,
		a.IsPriceIncludeTax
		,CASE WHEN (SELECT COUNT(1) FROM dbo.PM_RcvLine t WHERE t.SrcDoc_SrcDocNo=a.DocNo)=0 AND (SELECT COUNT(1) FROM dbo.PM_POLine t WHERE t.PurchaseOrder=a.ID AND t.Status=2)>0
		THEN 0 ELSE 1 END HasRcv
FROM    dbo.PM_PurchaseOrder a
        INNER JOIN dbo.Base_Organization o ON a.Org = o.ID
        INNER JOIN dbo.Base_Organization_Trl o1 ON o.ID = o1.ID
                                                   AND o1.SysMLFlag = 'zh-cn'
												   INNER JOIN dbo.CBO_Supplier s ON a.Supplier_Supplier=s.ID INNER JOIN dbo.CBO_Supplier_Trl s1 ON s.ID=s1.ID AND s1.SysMLFlag='zh-cn'
												   INNER JOIN dbo.Base_Currency cur ON a.FC=cur.ID INNER JOIN dbo.Base_Currency_Trl cur1 ON cur.ID=cur1.id AND cur1.SysMLFlag='zh-cn'
	WHERE a.Cancel_Canceled=0 --AND a.CreatedOn>'2023-03-01'

