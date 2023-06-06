SELECT TOP 10
a.ID
,a.Org
,o.Code OrgCode
,a.Code
,a.ShortName
,a1.Name							--供应商名称
,a.SearchCode
,a.Category
,cat.Code
,cat1.Name
,a.DescFlexField_PrivateDescSeg1
,a.DescFlexField_PrivateDescSeg2
,a.DescFlexField_PrivateDescSeg3
,a.DescFlexField_PrivateDescSeg11
,a.Territory						--地区ID
,ter.Code							--地区编码
,ter1.Name							--地区名称
,a.Purchaser						--业务员ID
,op.Code							--执行采购编码
,op1.Name							--执行采购名称
,op2.ID								--采购开发ID
,op2.Code							--采购开发编码
,op21.Name							--采购开发名称
,a.TradeCurrency					--交易币种
,a.CheckCurrency					--付款币种
,a.IsTaxPrice						--价格含税
,a.IsPriceListModify				--价目表可改
,a.PaymentTerm						--付款条件ID
,payTerm.Code						--付款条件编码
,payTerm1.Name						--付款条件名称
,a.APConfirmTerm					--立账条件ID
,ap.Code							--立账条件编码
,ap1.Name							--立账条件名称
,a.IsAPConfirmTermEditable			--立账条件可改
,a.InvoiceVerificationOrder			--发票核销顺序
,dbo.F_GetEnumName('UFIDA.U9.CBO.Enums.InvoiceVerificationOrdersEnum',a.InvoiceVerificationOrder,'zh-cn')
,a.InvoiceVerificationDetai			--核销明细
,dbo.F_GetEnumName('UFIDA.U9.CBO.Enums.SupplierVerificationModesEnum',a.InvoiceVerificationDetai,'zh-cn')
,a.DocVerificationOrder				--单据核销顺序
,dbo.F_GetEnumName('UFIDA.U9.CBO.SCM.Supplier.DocVerificationOrdersEnum',a.DocVerificationOrder,'zh-cn')
,a.ReceiptRule						--收货原则
,rec.Code							--收获原则编码
,rec1.Name							--收货原则名称
,a.IsReceiptRuleEditable			--收货原则可改
,a.TaxSchedule						--税组合
,tax.Code
,tax1.Name
,a.ContactObject
,bc.ID
,bc.Code
,bc.ContactType
,bc1.Name
,bc.PersonName_DisplayName
,bc.DefaultPhoneNum
,bc.DefaultMobilNum
,bc.DefaultEmail
,a.OfficialLocation
,loc.Code
,loc1.Name
,a.RegisterLocation
,regloc.Code
,regloc1.Name
FROM dbo.CBO_Supplier a 
INNER JOIN dbo.CBO_Supplier_Trl a1 ON a.ID=a1.ID AND a1.SysMLFlag='zh-cn'
INNER JOIN dbo.Base_Organization o ON a.Org=o.ID
LEFT JOIN Base_Territory ter ON a.Territory=ter.ID LEFT JOIN dbo.Base_Territory_Trl ter1 ON ter.ID=ter1.ID AND ter1.SysMLFlag='zh-cn'
LEFT JOIN dbo.CBO_PaymentTerm payTerm ON a.PaymentTerm=payTerm.ID LEFT JOIN dbo.CBO_PaymentTerm_Trl payTerm1 ON payTerm.ID=payTerm1.ID AND payTerm1.SysMLFlag='zh-cn'
LEFT JOIN dbo.CBO_APConfirmTerm ap ON a.APConfirmTerm=ap.ID LEFT JOIN dbo.CBO_APConfirmTerm_Trl ap1 ON ap.ID=ap1.ID AND ap1.SysMLFlag='zh-cn'
LEFT JOIN CBO_ReceiptRule rec ON a.ReceiptRule=rec.ID LEFT JOIN dbo.CBO_ReceiptRule_Trl rec1 ON rec.ID=rec1.ID AND rec1.SysMLFlag='zh-cn'
LEFT JOIN dbo.CBO_TaxSchedule tax ON a.TaxSchedule=tax.ID LEFT JOIN dbo.CBO_TaxSchedule_Trl tax1 ON tax.ID=tax1.ID AND tax1.SysMLFlag='zh-cn'
LEFT JOIN dbo.CBO_Operators op ON a.Purchaser=op.ID LEFT JOIN dbo.CBO_Operators_Trl op1 ON op.ID=op1.ID AND op1.SysMLFlag='zh-cn'
LEFT JOIN dbo.CBO_Operators op2 ON a.DescFlexField_PrivateDescSeg4=op2.Code LEFT JOIN dbo.CBO_Operators_Trl op21 ON op2.ID=op21.ID AND op21.SysMLFlag='zh-cn'
LEFT JOIN dbo.CBO_SupplierContact cm ON a.ID=cm.Supplier AND cm.IsDefault=1
LEFT JOIN dbo.Base_Contact bc ON cm.Contact=bc.ID LEFT JOIN dbo.Base_Contact_Trl bc1 ON bc.ID=bc1.ID AND bc1.SysMLFlag='zh-cn'
LEFT JOIN dbo.Base_Location loc ON a.OfficialLocation=loc.ID LEFT JOIN dbo.Base_Location_Trl loc1 ON loc.ID=loc1.ID AND loc1.SysMLFlag='zh-cn'
LEFT JOIN dbo.Base_Location regloc ON a.RegisterLocation=regloc.ID LEFT JOIN dbo.Base_Location_Trl regloc1 ON regloc.ID=regloc1.ID AND regloc1.SysMLFlag='zh-cn'
--LEFT JOIN dbo.Base_Contact contact ON a.ContactObject=contact.ID
LEFT JOIN dbo.CBO_SupplierCategory cat ON a.Category=cat.ID LEFT JOIN dbo.CBO_SupplierCategory_Trl cat1 ON cat.ID=cat1.ID AND cat1.SysMLFlag='zh-cn'
WHERE 1=1 
AND a.Code='2.RYTX.001'
AND o.Code='100'
--ORDER BY a.CreatedOn DESC

--SELECT TOP 10 * FROM dbo.V_Cust_Operators4OA

--采购业务员
--采购开发


