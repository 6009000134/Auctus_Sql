/*
����������Ϣ
*/
ALTER  VIEW v_cust_MOPickList
AS
    SELECT  a.ID MOID ,--����ID
            a.DocNo ,--������
            a.Org ,
            b.ID LineID ,--������ID
            b.DocLineNO ,--�����к�
            b.ItemMaster ItemID ,
            m.Code ,
            m.Name ,
            m.SPECS ,
            b.ActualReqQty ,--ʵ��������
            b.IssuedQty ,--�ѷ�������
            CONVERT(VARCHAR(20),b.ActualReqDate,23)ActualReqDate ,--ʵ����������
            CONVERT(VARCHAR(20),b.PlanReqDate,23)PlanReqDate ,--�ƻ���������
            b.IssueStyle ,--���Ϸ�ʽ
            b.SupplyWh ,--�洢�ص�
            1 IsEdit
    FROM    dbo.MO_MO a
            INNER JOIN dbo.MO_MOPickList b ON a.ID = b.MO
            INNER JOIN dbo.CBO_ItemMaster m ON b.ItemMaster = m.ID
    WHERE   a.DocState IN ( 1, 2 );


	