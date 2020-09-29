--请款
--付款请款单表头
SELECT 
a.DocNo,b.ID,b.LineNum,c.LineNum
,a.CreatedOn,a.CreatedBy
,a.ApprovedBy,a.ApprovedOn
,a.CancelApprovedBy,a.CancelApprovedOn
,a.Org
,a.BusinessType--业务类型
,dbo.F_GetEnumName('UFIDA.U9.Base.Doc.BusinessTypeEnum',a.BusinessType,'zh-cn')BusinessTypeName
,a.DocumentType,d.Code,d1.Name--单据类型
,a.ExpectPayDate--预计付款日
,a.PayRFDate--申请日期
,a.BusinessDate--业务日期
,a.FC--本币
,a.ReqFundAC--核算币种
,a.ReqFundPC--币种
,a.ReqFundMC--中间币种
,a.SOB--账簿，默认取账簿类型为“主账簿”，即SobType=0
,a.ERType--汇率类型
,a.ACToMCXR--汇率
,a.PCToMCXR--汇率
,a.PCToFCXR--汇率
,a.AllowVariance--允许误差
,a.IsDiffCurReq--异币种付款（单头币种和付款本币金额币种不一致，17年有单据问题，之后无异币种付款）
,a.Dept--部门
,a.SrcBizOwnerOrg--来源业务所属组织
,a.Transactor,e.Code,e1.Name--业务员
,a.RFTotalMoney--请款总金额
,a.DocStatus--状态
,a.IsCashierConfirmed--出纳确认，生成付款单
,a.PayMode,dbo.F_GetEnumName('UFIDA.U9.Base.Doc.BusinessTypeEnum',a.PayMode,'zh-cn')PayModeName--付款方式
,a.RequestObjType,dbo.F_GetEnumName('UFIDA.U9.CBO.FI.Enums.RecPayObjectTypeEnum',a.RequestObjType,'zh-cn')RequestObjTypeName
,a.FCTotalMoney--付款本币金额
,a.IsAutoConfirm--自动确认
,a.Project,a.Task
,a.SrcType--来源类型
--,a.BizOrg--业务组织
--,a.SettleOrg--结算组织
--,a.WFCurrentState,a.WFOriginalState
,b.Supp_Supplier,b.SuppSite_SupplierSite
,b.SttlMethod,s.Code SttlMethodCode,s1.Name SttlMethodName
,b.RFTotalMoney,b.RFPayMoney
,c.RFMoney_NonTax,c.RFMoney_Tax,c.RFMoney_GoodsTax,c.RFMoney_FeeTax,c.RFMoney_Fee,c.RFMoney_TotalMoney,c.RFPayMoney

,c.PrePayType
,dbo.F_GetEnumName('UFIDA.U9.CBO.FI.Enums.PrePayObjEnum',c.PrePayType,'zh-cn')PrePayTypeName

FROM AP_PayReqBillHead a --请款单头
INNER JOIN AP_PayReqFundUse b ON a.ID=b.PayReqFundHead--请款用途
INNER JOIN dbo.AP_PayReqFundDetail c ON b.ID=c.PayReqFundUse--请款明细
LEFT JOIN AP_PayReqFundDocType d ON a.DocumentType=d.ID LEFT JOIN dbo.AP_PayReqFundDocType_Trl d1 ON a.DocumentType=d1.ID AND ISNULL(d1.SysMLFlag,'zh-cn')='zh-cn'--单据类型
LEFT JOIN dbo.CBO_Operators e ON a.Transactor=e.ID LEFT JOIN dbo.CBO_Operators_Trl e1 ON a.Transactor=e1.ID AND ISNULL(e1.SysMLFlag,'zh-cn')='zh-cn'--业务员
LEFT JOIN AP_PayReqFundCapSimu f ON a.ID=f.PayReqFundHead--付款请款单资金模拟
LEFT JOIN CBO_SettlementMethod s ON b.SttlMethod=s.ID
LEFT JOIN dbo.CBO_SettlementMethod_Trl s1 ON s.ID=s1.ID
WHERE 1=1 
AND a.Org=1001708020135665
--AND b.ID=1001709114526001
AND a.DocNo='RA-30191025003'
--AND b.ID=1001912270011103
--AND d.Code='002'
--AND dbo.F_GetEnumName('UFIDA.U9.Base.Doc.BusinessTypeEnum',a.BusinessType,'zh-cn')='预付款'
--AND b.ReqFundUse=1

--AND a.AllowVariance>0
--AND a.IsDiffCurReq=1--异币种付款






