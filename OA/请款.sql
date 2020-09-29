--���
--��������ͷ
SELECT 
a.DocNo,b.ID,b.LineNum,c.LineNum
,a.CreatedOn,a.CreatedBy
,a.ApprovedBy,a.ApprovedOn
,a.CancelApprovedBy,a.CancelApprovedOn
,a.Org
,a.BusinessType--ҵ������
,dbo.F_GetEnumName('UFIDA.U9.Base.Doc.BusinessTypeEnum',a.BusinessType,'zh-cn')BusinessTypeName
,a.DocumentType,d.Code,d1.Name--��������
,a.ExpectPayDate--Ԥ�Ƹ�����
,a.PayRFDate--��������
,a.BusinessDate--ҵ������
,a.FC--����
,a.ReqFundAC--�������
,a.ReqFundPC--����
,a.ReqFundMC--�м����
,a.SOB--�˲���Ĭ��ȡ�˲�����Ϊ�����˲�������SobType=0
,a.ERType--��������
,a.ACToMCXR--����
,a.PCToMCXR--����
,a.PCToFCXR--����
,a.AllowVariance--�������
,a.IsDiffCurReq--����ָ����ͷ���ֺ͸���ҽ����ֲ�һ�£�17���е������⣬֮��������ָ��
,a.Dept--����
,a.SrcBizOwnerOrg--��Դҵ��������֯
,a.Transactor,e.Code,e1.Name--ҵ��Ա
,a.RFTotalMoney--����ܽ��
,a.DocStatus--״̬
,a.IsCashierConfirmed--����ȷ�ϣ����ɸ��
,a.PayMode,dbo.F_GetEnumName('UFIDA.U9.Base.Doc.BusinessTypeEnum',a.PayMode,'zh-cn')PayModeName--���ʽ
,a.RequestObjType,dbo.F_GetEnumName('UFIDA.U9.CBO.FI.Enums.RecPayObjectTypeEnum',a.RequestObjType,'zh-cn')RequestObjTypeName
,a.FCTotalMoney--����ҽ��
,a.IsAutoConfirm--�Զ�ȷ��
,a.Project,a.Task
,a.SrcType--��Դ����
--,a.BizOrg--ҵ����֯
--,a.SettleOrg--������֯
--,a.WFCurrentState,a.WFOriginalState
,b.Supp_Supplier,b.SuppSite_SupplierSite
,b.SttlMethod,s.Code SttlMethodCode,s1.Name SttlMethodName
,b.RFTotalMoney,b.RFPayMoney
,c.RFMoney_NonTax,c.RFMoney_Tax,c.RFMoney_GoodsTax,c.RFMoney_FeeTax,c.RFMoney_Fee,c.RFMoney_TotalMoney,c.RFPayMoney

,c.PrePayType
,dbo.F_GetEnumName('UFIDA.U9.CBO.FI.Enums.PrePayObjEnum',c.PrePayType,'zh-cn')PrePayTypeName

FROM AP_PayReqBillHead a --��ͷ
INNER JOIN AP_PayReqFundUse b ON a.ID=b.PayReqFundHead--�����;
INNER JOIN dbo.AP_PayReqFundDetail c ON b.ID=c.PayReqFundUse--�����ϸ
LEFT JOIN AP_PayReqFundDocType d ON a.DocumentType=d.ID LEFT JOIN dbo.AP_PayReqFundDocType_Trl d1 ON a.DocumentType=d1.ID AND ISNULL(d1.SysMLFlag,'zh-cn')='zh-cn'--��������
LEFT JOIN dbo.CBO_Operators e ON a.Transactor=e.ID LEFT JOIN dbo.CBO_Operators_Trl e1 ON a.Transactor=e1.ID AND ISNULL(e1.SysMLFlag,'zh-cn')='zh-cn'--ҵ��Ա
LEFT JOIN AP_PayReqFundCapSimu f ON a.ID=f.PayReqFundHead--�������ʽ�ģ��
LEFT JOIN CBO_SettlementMethod s ON b.SttlMethod=s.ID
LEFT JOIN dbo.CBO_SettlementMethod_Trl s1 ON s.ID=s1.ID
WHERE 1=1 
AND a.Org=1001708020135665
--AND b.ID=1001709114526001
AND a.DocNo='RA-30191025003'
--AND b.ID=1001912270011103
--AND d.Code='002'
--AND dbo.F_GetEnumName('UFIDA.U9.Base.Doc.BusinessTypeEnum',a.BusinessType,'zh-cn')='Ԥ����'
--AND b.ReqFundUse=1

--AND a.AllowVariance>0
--AND a.IsDiffCurReq=1--����ָ���






