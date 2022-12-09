SELECT  a.ID 
        ,a.DocNo 
		,b.ReqQtyPBU,b.ReqQtyPU,b.ReqQtySBU,b.ReqQtySU,b.ReqQtyTBU,b.ReqQtyTU--,b.ReqQtyTBU,b.ReqQtyTBU
		,b.ReqQtyReqUOM
		,b.ApprovedQtyPBU,b.ApprovedQtyPU,b.ApprovedQtySBU,b.ApprovedQtySU,b.ApprovedQtyTBU,b.ApprovedQtyTU--,b.ReqQtyTBU,b.ReqQtyTBU
		,b.ApprovedQtyReqUOM,b.ApprovedQtyReqBUOM
        ,b.DocLineNo 
        ,b.TotalToPOQtyTBU					as	已转订单量2
        ,b.TotalToPOQtyTU					as	已转订单量1
        ,b.TotalToPRQtyTBU					as  累计转PR数量2
        ,b.TotalToPRQtyTU					as  累计转PR数量TU
		,b.CurOrgPuQtyPU					as  本组织采购数量_计价单位
		,b.CurOrgPuQtyRBU					as  本组织采购数量_需求基准单位
		,b.CurOrgPuQtyRU					as  本组织采购数量_需求单位
		,b.CurOrgPuQtyTBU					as  本组织采购数量_交易基准单位
		,b.CurOrgPuQtyTU					as  本组织采购数量_交易单位
		,b.CurOrgToPOQtyTBU					as  本组织转采购数量2
		,b.CurOrgToPOQtyTBUBeforeDoubleQty	as  本组织转PO数量采购基准单位倍量前
		,b.CurOrgToPOQtyTU					as  本组织转采购数量
		,b.CurOrgToPOQtyTUBeforeDoubleQty	as  本组织转PO数量采购单位倍量前
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