--InvTrans_InvTotalSelects 
--InvTrans_MonthClose ����½��
--InvTrans_AccountPeriodLine ����ڼ��춯������
--InvTrans_AccountPeriodLineBin ����ڼ��춯��λ��




--InvTrans_TransLine ����춯��ϸ������
--InvTrans_TransLineBin ����춯��ϸ��λ��
--InvTrans_TransLineCost 	����춯��ϸ���ɱ���
--InvTrans_AccountPeriodLineCost ����ڼ��춯�ɱ���


--SELECT * FROM InvTrans_TransLine
SELECT b.Code,b.Name FROM dbo.InvTrans_TransLine a LEFT JOIN dbo.CBO_ItemMaster b ON a.Product=b.ID

SELECT * FROM dbo.InvTrans_Trans WHERE BizType

