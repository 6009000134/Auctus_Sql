SELECT  a.ID 
        ,a.DocNo 
		,b.ReqQtyPBU,b.ReqQtyPU,b.ReqQtySBU,b.ReqQtySU,b.ReqQtyTBU,b.ReqQtyTU--,b.ReqQtyTBU,b.ReqQtyTBU
		,b.ReqQtyReqUOM
		,b.ApprovedQtyPBU,b.ApprovedQtyPU,b.ApprovedQtySBU,b.ApprovedQtySU,b.ApprovedQtyTBU,b.ApprovedQtyTU--,b.ReqQtyTBU,b.ReqQtyTBU
		,b.ApprovedQtyReqUOM,b.ApprovedQtyReqBUOM
        ,b.DocLineNo 
        ,b.TotalToPOQtyTBU					as	��ת������2
        ,b.TotalToPOQtyTU					as	��ת������1
        ,b.TotalToPRQtyTBU					as  �ۼ�תPR����2
        ,b.TotalToPRQtyTU					as  �ۼ�תPR����TU
		,b.CurOrgPuQtyPU					as  ����֯�ɹ�����_�Ƽ۵�λ
		,b.CurOrgPuQtyRBU					as  ����֯�ɹ�����_�����׼��λ
		,b.CurOrgPuQtyRU					as  ����֯�ɹ�����_����λ
		,b.CurOrgPuQtyTBU					as  ����֯�ɹ�����_���׻�׼��λ
		,b.CurOrgPuQtyTU					as  ����֯�ɹ�����_���׵�λ
		,b.CurOrgToPOQtyTBU					as  ����֯ת�ɹ�����2
		,b.CurOrgToPOQtyTBUBeforeDoubleQty	as  ����֯תPO�����ɹ���׼��λ����ǰ
		,b.CurOrgToPOQtyTU					as  ����֯ת�ɹ�����
		,b.CurOrgToPOQtyTUBeforeDoubleQty	as  ����֯תPO�����ɹ���λ����ǰ
FROM    dbo.PR_PR a
        INNER JOIN dbo.PR_PRLine b ON a.ID = b.PR
WHERE   a.DocNo = 'PR30221206001'
--PR30221201010
--{"PRID":1002212010084081,"PRDocNo":"PR30221201010","PRDocLineNo":10,"OriginalPONum":100,"PONum":50}
--{"PRID":1002212060440011,"PRDocNo":"PR30221206001","PRDocLineNo":10,"OriginalPONum":90,"PONum":50}
SELECT 
*
FROM dbo.PR_PRDocType a
WHERE a.Code='PR30112'
--IsAMADoc

--UPDATE dbo.PR_PRDocType SET IsAMADoc=0 WHERE Code='PR30112'
--UPDATE dbo.PR_PRDocType SET IsAMADoc=1 WHERE Code='PR30112'