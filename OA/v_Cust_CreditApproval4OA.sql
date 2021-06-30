--���õȼ�������
ALTER VIEW v_Cust_CreditApproval4OA
AS
SELECT a.ID CreditControlObjectID--���ö���ID
,a.Organization Org,o.Code OrgCode,o1.Name OrgName--��֯
,a.Customer,cus.Code CustomerCode,cus1.Name CustomerName--�ͻ�
,c.ID PolicyID,c.RefrencePolicy--����ID��PolicyID���ã�ֻ��RefrencePolicy
,c.Code PolicyCode,c1.Name PolicyName
,c.ControlFlow_ControlPoint ControlPoint,dbo.F_GetEnumName('UFIDA.U9.CC.Enum.ControlPointEnum',c.ControlFlow_ControlPoint,'zh-cn')ControlPointName--���ÿ��Ƶ�
,f.ID CreditLevelID,f.ReferenceLevel,f.Code CreditLevelCode,f1.Name CreditLevelName--���õȼ�
,cur.CreditContent_CreditLimit CreditLimit
FROM dbo.CC_CreditControlObject a INNER JOIN dbo.CC_ObjectCreditPolicy b ON a.ID=b.CreditObject
INNER JOIN dbo.CC_CreditPolicy c ON b.CreditPolicy=c.ID INNER JOIN dbo.CC_CreditPolicy_Trl c1 ON c.id=c1.ID AND ISNULL(c1.SysMLFlag,'zh-cn')='zh-cn'
INNER JOIN dbo.CC_ObjectCreditLevel d ON b.ID=d.ObjectCreditPolicy
INNER JOIN dbo.CC_CreditLevel f ON d.CreditLevel=f.ID INNER JOIN dbo.CC_CreditLevel_Trl f1 ON f.ID=f1.id AND ISNULL(f1.SysMLFlag,'zh-cn')='zh-cn'
INNER JOIN dbo.CBO_Customer cus ON a.Customer=cus.ID INNER JOIN dbo.CBO_Customer_Trl cus1 ON cus.ID=cus1.ID AND ISNULL(cus1.SysMLFlag,'zh-cn')='zh-cn'
INNER JOIN dbo.Base_Organization o ON a.Organization=o.ID INNER JOIN dbo.Base_Organization_Trl o1 ON o.ID=o1.ID AND ISNULL(o1.SysMLFlag,'zh-cn')='zh-cn'
LEFT JOIN dbo.CC_CreditLevelCurrency cur ON f.ReferenceLevel=cur.CreditLevel