--��������
SELECT  
--a.ID,b.ID ,c.id,d.id,e.ID,f.ID,g.ID
a.Applicant,a.DateofRequest,a.ProposeDept,a.BizOrg--�����ˣ��������ڣ����벿�ţ�������֯
,b.CreditPolicy,f.ID,f.CreditPolicy,poli.ID
,c.ObjectType,dbo.F_GetEnumName('UFIDA.U9.CBO.DTOs.ObjectTypeEnum',c.ObjectType,'zh-cn')ObjectTypeName--�������� UFIDA.U9.CBO.DTOs.ObjectTypeEnum 0-�ͻ�������ȥc.customer���ͻ���		
,c.OperatingOrg--Ӫ����֯
,c.Customer,cus1.Name CustomerName,cus.Code CustomerCode--����:0-�ͻ�		
--,c.CustomerSite,c.Seller,c.Department--�ͻ�λ��--ҵ��Ա--����		
,poli.ID PolicyID,poli.Code PolicyCode,poli1.Name PolicyName--����
,a.ControlPoint,dbo.F_GetEnumName('UFIDA.U9.CC.Enum.ControlPointEnum',a.ControlPoint,'zh-cn')ControlPointName
,b.ID CreditLevelID,b.Code CreditLevelCode,b1.Name CreditLevelName
,a.CreditLimit--�����~��
,e.CreditContent_MaxOverdueDays--��������
FROM CC_ObjectCreditLevelApproval a
INNER JOIN CC_CreditLevel b ON a.CreditLevel=b.ID LEFT JOIN dbo.CC_CreditLevel_Trl b1 ON b.id=b1.ID AND ISNULL(b1.SysMLFlag,'zh-cn')='zh-cn'
INNER JOIN CC_CreditControlObject c ON a.CreditObject=c.ID
INNER JOIN CC_ObjectCreditLevel d ON a.ObjectCreditLevel=d.ID
INNER JOIN CC_ObjectCreditLevelApprovalCurrency e ON a.ID=e.ObjectCreditLevelApproval
INNER JOIN CC_ObjectCreditPolicy f ON a.ObjectCreditPolicy=f.ID LEFT JOIN dbo.CC_ObjectCreditPolicy_Trl f1 ON f.ID=f1.ID AND ISNULL(f1.SysMLFlag,'zh-cn')='zh-cn'
LEFT JOIN CC_CreditPolicy poli ON f.CreditPolicy=poli.ID LEFT JOIN dbo.CC_CreditPolicy_Trl poli1 ON poli.ID=poli1.ID AND ISNULL(poli1.SysMLFlag,'zh-cn')='zh-cn'
LEFT JOIN CC_ObjectCreditLevelApproval g ON a.ReferenceObjectCreditLevelApproval=g.ID
LEFT JOIN dbo.CBO_Customer cus ON c.Customer=cus.ID LEFT JOIN dbo.CBO_Customer_Trl cus1 ON cus.ID=cus1.ID AND ISNULL(cus1.SysMLFlag,'zh-cn')='zh-cn'
WHERE cus.Code='1.1.CXTK.001'
/*
���õȼ�
1����������д���ɣ�0-�ͻ�
2����ѡ�������ߣ��ٲ���ѡ���õȼ�
*/

--2.1.MOTO.001


SELECT * FROM dbo.CC_ObjectCreditPolicy




