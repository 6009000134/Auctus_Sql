--TODO:校验TC和FC币种关系
DECLARE @somodify BIGINT=1002211250110039
SELECT 
a.ID,a.DocNo,a.ModifyReason,a.ModifyCountTH,a.DescFlexField_PrivateDescSeg1
,a1.*
FROM dbo.SM_SOModify a
LEFT JOIN dbo.SM_SOModify_Trl a1 ON a.ID=a1.ID AND a1.SysMLFlag='zh-cn'
WHERE 1=1 AND a.DocNo='SOM30202211002'
--AND a.id=1001711060055711
/*
变更类型有：新增、修改、删除
删除行、子行可以体现为删除
新增行、子行则重点体现数量、交期、金额
OA中变更单 单价金额是否要控制显示
*/
--POM30210626003
--POM30210615004
--	销售订单变更单行  变更字段和内容
SELECT b.SOModifyType,dbo.F_GetEnumName('UFIDA.U9.SM.SOModify.SOModifyTypeEnum',b.SOModifyType,'zh-cn')SOModifyTypeName,* 
FROM dbo.SM_SOModifyLine b WHERE b.SOModify=@somodify ORDER BY b.SOModifyType
--	销售订单变更单销售订单行
SELECT c.LineModifyType,dbo.F_GetEnumName('UFIDA.U9.SM.SOModify.LineModifyTypeEnum',c.LineModifyType,'zh-cn')LineModifyTypeName
,c.DocLineNo,* FROM SM_SOModifySOLine c WHERE  c.SOModify=@somodify
--	销售订单变更单订单出货计划行
SELECT c.LineModifyType,dbo.F_GetEnumName('UFIDA.U9.SM.SOModify.LineModifyTypeEnum',c.LineModifyType,'zh-cn')LineModifyTypeName
,c.DocSubLineNo,* FROM SM_SOModifySOShipline c WHERE  c.SOModify=@somodify
----销售订单变更单地址
--SELECT c.SOModify FROM dbo.SM_SOModifySOAddress c WHERE c.LineModifyType=0
----	销售订单变更单订单分期立账行
--SELECT c.LineModifyType,dbo.F_GetEnumName('UFIDA.U9.SM.SOModify.LineModifyTypeEnum',c.LineModifyType,'zh-cn')LineModifyTypeName
--,c.DocSubLineNo,* FROM SM_SOModifySOARLine c WHERE  c.SOModify=@somodify
----	销售订单变更单联系人
--SELECT * FROM SM_SOModifySOContact c WHERE  c.SOModify=@somodify
----	销售订单变更单折扣行
--SELECT * FROM SM_SOModifySODiscount c WHERE  c.SOModify=@somodify
------销售订单变更单费用行
----SELECT * FROM SM_SOModifySOFee c WHERE  c.SOModify=1002209201672223
--销售订单变更单备注
SELECT * FROM SM_SOModifySOMemo c WHERE  c.SOModify=@somodify
----	销售订单变更单订单分期收款行
--SELECT * FROM SM_SOModifySORecLine c WHERE  c.SOModify=@somodify
------	销售订单变更单销售订船期行
----SELECT * FROM SM_SOModifySOSailingDate c WHERE  c.SOModify=@somodify
--	销售订单变更单销售订单税行
SELECT * FROM SM_SOModifySOTax c WHERE  c.SOModify=@somodify


/*

社融增速                1 
企业中长期贷款          1
M1-M2                   1
货币政策方向            1
PMI                     1
工业企业利润增速/ROE    1
库存周期指标            1
汽车销量                1
房地产                  1
估值分位数              1
股权风险溢价            1
指数复利增长线          1

*/
