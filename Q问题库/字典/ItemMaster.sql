/*
��Ʒ����MOQ\MPQ\�ɹ�����ͬ������Ӧ����Ʒ�۲��
*/

SELECT 
a.ID,a.Code
,p.MinRcvQty--MOQ
,p.PurchaseBatchQty--MPQ
,mrp.PurBackwardProcessLT--	�ɹ�����ǰ��(��)
,mrp.PurForwardProcessLT--	�ɹ�Ԥ��ǰ��(��)
,mrp.PurProcessLT--�ɹ�������ǰ��(��)
,mrp.FixedLT--�̶���ǰ��(��)
,mrp.LTBatch--	��ǰ������
,mrp.SumLT--������ǰ��(��)
,mrp.DemandRule--����������:�ϸ�/���ϸ�
,mrp.IsControlByDC--�Ƿ��������ſ���
FROM dbo.CBO_ItemMaster a 
INNER JOIN dbo.CBO_PurchaseInfo p ON a.ID=p.ItemMaster
INNER JOIN dbo.CBO_InventoryInfo i ON a.ID=i.ItemMaster
INNER JOIN dbo.CBO_MrpInfo mrp ON a.ID=mrp.ItemMaster
WHERE a.org=(SELECT id FROM dbo.Base_Organization WHERE code='300')
