SELECT TOP 10
a.ID
,a.Org
,o.Code OrgCode
,a.Code
,a.ShortName
,a1.Name							--��Ӧ������
,a.SearchCode
,a.Category
,cat.Code
,cat1.Name
,a.DescFlexField_PrivateDescSeg1
,a.DescFlexField_PrivateDescSeg2
,a.DescFlexField_PrivateDescSeg3
,a.DescFlexField_PrivateDescSeg11
,a.Territory						--����ID
,ter.Code							--��������
,ter1.Name							--��������
,a.Purchaser						--ҵ��ԱID
,op.Code							--ִ�вɹ�����
,op1.Name							--ִ�вɹ�����
,op2.ID								--�ɹ�����ID
,op2.Code							--�ɹ���������
,op21.Name							--�ɹ���������
,a.TradeCurrency					--���ױ���
,a.CheckCurrency					--�������
,a.IsTaxPrice						--�۸�˰
,a.IsPriceListModify				--��Ŀ��ɸ�
,a.PaymentTerm						--��������ID
,payTerm.Code						--������������
,payTerm1.Name						--������������
,a.APConfirmTerm					--��������ID
,ap.Code							--������������
,ap1.Name							--������������
,a.IsAPConfirmTermEditable			--���������ɸ�
,a.InvoiceVerificationOrder			--��Ʊ����˳��
,dbo.F_GetEnumName('UFIDA.U9.CBO.Enums.InvoiceVerificationOrdersEnum',a.InvoiceVerificationOrder,'zh-cn')
,a.InvoiceVerificationDetai			--������ϸ
,dbo.F_GetEnumName('UFIDA.U9.CBO.Enums.SupplierVerificationModesEnum',a.InvoiceVerificationDetai,'zh-cn')
,a.DocVerificationOrder				--���ݺ���˳��
,dbo.F_GetEnumName('UFIDA.U9.CBO.SCM.Supplier.DocVerificationOrdersEnum',a.DocVerificationOrder,'zh-cn')
,a.ReceiptRule						--�ջ�ԭ��
,rec.Code							--�ջ�ԭ�����
,rec1.Name							--�ջ�ԭ������
,a.IsReceiptRuleEditable			--�ջ�ԭ��ɸ�
,a.TaxSchedule						--˰���
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

--�ɹ�ҵ��Ա
--�ɹ�����


