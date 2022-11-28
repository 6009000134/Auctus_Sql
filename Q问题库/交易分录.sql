SELECT TOP 10 * FROM dbo.GL_Voucher a
SELECT TOP 10 * FROM dbo.GL_Entry WHERE NMDocNo='SM91202208002_10'
SELECT TOP 10 * FROM AAI_TransactionEntry
SELECT TOP 10 * FROM dbo.AAI_TransEntryHead



SELECT a.vou FROM dbo.SM_SOLine a 

SELECT  a.CreatedOn,a.AccountedCr 'dai',a.EnteredCr 'dai2',a.AccountedDr 'jie',a.EnteredDr 'jie2',a.Account 
,b.*,v.DocNo,v.VoucherSourceMethod,dbo.F_GetEnumName('UFIDA.U9.GL.Voucher.VoucherSourceMethod',v.VoucherSourceMethod,'zh-cn')VoucherSourceMethodName,v.SourceVoucherTemplate
FROM GL_Entry a INNER JOIN  dbo.GL_Entry_Trl b ON a.ID=b.ID INNER JOIN dbo.GL_Voucher v ON a.Voucher=v.ID 
WHERE 1=1
--AND (b.AccountDisplayName LIKE '%工资%'and b.AccountDisplayName LIKE '%信息%')
AND v.Org=(SELECT id FROM dbo.Base_Organization WHERE code='200')
ORDER BY a.CreatedOn desc
--1001807050072734

SELECT * FROM GL_VoucherTemplateData a INNER JOIN dbo.GL_VoucherTemplateData_Trl b ON a.id=b.id 
WHERE a.id=1001803010044054
--SELECT code FROM dbo.Base_Organization WHERE id=1001806280045676
SELECT * FROM GL_AllocationTemplate
SELECT * FROM GL_RecurringTemplate WHERE id=1001807050072734