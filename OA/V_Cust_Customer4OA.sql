/*
客户信息（带立账条件）
*/

alter VIEW V_Cust_Customer4OA AS
SELECT a.ID,a.Code,a1.Name,a.Org,a2.Code as OrgCode 
,c.ID ARConfirmTerm,c.Code ARConfirmTerm_Code,c1.Name ARConfirmTerm_Name
,a.PayCurrency,cur.Code PayCurrencyCode,a.Saleser Seller,op.Code SellerCode,op1.Name SellerName
,a.TaxSchedule,tax.Code TaxScheduleCode,tax1.Name TaxScheduleName
,a.DescFlexField_PubDescSeg6 SalesPerson
,a.DescFlexField_PubDescSeg7 SalesManager
,a.DescFlexField_PubDescSeg8 ProductManager
,a.Territory AreaID,t.Code AreaCode,t1.Name AreaName
,con.ConfirmDateType
,dbo.F_GetEnumName('UFIDA.U9.CBO.Enums.ConfirmDateTypeEnum',con.ConfirmDateType,'zh-cn')ConfirmDateTypeName
,CASE WHEN con.ConfirmDateType=3 THEN 1 ELSE 0 END IsUserDefine
FROM dbo.CBO_Customer AS a
INNER JOIN dbo.CBO_Customer_Trl AS a1 ON a.id=a1.ID
					AND a1.SysMLFlag='zh-cn'
INNER JOIN dbo.Base_Organization AS a2 ON a.Org=a2.ID					
LEFT JOIN CBO_ARConfirmTerm c ON a.ARConfirmTerm=c.ID AND c.Effective_IsEffective=1 AND GETDATE() BETWEEN c.Effective_EffectiveDate AND c.Effective_DisableDate
LEFT JOIN dbo.CBO_ARConfirmTerm_Trl c1 ON c.ID=c1.ID AND ISNULL(c1.SysMLFlag,'zh-cn')='zh-cn'
LEFT JOIN dbo.Base_Currency cur ON a.PayCurrency=cur.ID
LEFT JOIN dbo.CBO_Operators op ON a.Saleser=op.ID
LEFT JOIN dbo.CBO_Operators_Trl op1 ON op.ID=op1.ID AND ISNULL(op1.SysMLFlag,'zh-cn')='zh-cn'
LEFT JOIN dbo.CBO_TaxSchedule tax ON a.TaxSchedule=tax.ID
LEFT JOIN dbo.CBO_TaxSchedule_Trl tax1 ON tax.ID=tax1.ID AND ISNULL(tax1.SysMLFlag,'zh-cn')='zh-cn'
LEFT JOIN CBO_ARInstalmentTerm con ON c.ID=con.ARAccrueTerm
LEFT JOIN Base_Territory t ON a.Territory=t.ID
LEFT JOIN dbo.Base_Territory_Trl t1 ON t1.ID=t.ID AND ISNULL(t1.SysMLFlag,'zh-cn')='zh-cn'
WHERE a.Effective_IsEffective = 1
AND a.Effective_EffectiveDate <=GETDATE()
AND a.Effective_DisableDate>=GETDATE()
AND a.IsHoldRelease = 0
AND a.State=1




