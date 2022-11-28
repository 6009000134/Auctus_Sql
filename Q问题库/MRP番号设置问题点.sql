--UPDATE dbo.MO_MODocType SET DescFlexField_PrivateDescSeg1=''
--UPDATE dbo.MO_IssueDocType SET DescFlexField_PrivateDescSeg1=''
--UPDATE dbo.SM_ForecastOrderDocType SET DescFlexField_PrivateDescSeg1=''

/*
问题点：
1、预测订单不能自动生成番号
2、预测订单无番号，对应转的SO不会自动生成番号
3、

MRP参数不勾选按番号合行，当同一料品、不同番号批量释放时，合行后PR无番号

1、FO需要插件自动生成对应番号
2、FO备料单机头，SO下单成品情况，验证FO单机头和SO成品存在BOM关系
3、FO备料原材料情况，SO下成品订单情况，只能FO需求回来后通过形态转换单(主要由于项目的长周期生产备料)



*/
--335110002 23001 23004