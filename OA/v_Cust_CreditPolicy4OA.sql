--信用政策选择按钮用Refrencepolicy为空的数据
CREATE VIEW v_Cust_CreditPolicy4OA
as
SELECT a.ID PolicyID,RefrencePolicy,a.Code,a1.Name,a.Org,a.ControlFlow_ControlPoint ControlPoint ,dbo.F_GetEnumName('UFIDA.U9.CC.Enum.ControlPointEnum',a.ControlFlow_ControlPoint,'zh-cn')ControlPointName
FROM dbo.CC_CreditPolicy a INNER JOIN dbo.CC_CreditPolicy_Trl a1 ON a.ID=a1.ID AND ISNULL(a1.SysMLFlag,'zh-cn')='zh-cn'

