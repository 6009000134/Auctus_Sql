/*
�ʲ���Ƭ��Դ����
*/
ALTER VIEW v_Cust_AssetSrcDoc4OA
as
SELECT  a.ID DispenseID ,--SourcDocLineID
        c.Org,
		o.Code OrgCode,
        c.DocNo SrcDoc ,--�ջ�����
        b.DocLineNo SrcDocLineNo ,--�ջ�����
		sup.ID SupplierID,
		sup.Code SupplierCode,
		sup1.Name SupplierName,
        m.Code,--�Ϻ�
        m.Name,--Ʒ��
        m.ID ItemID ,
        a.CanProcessQtyTU ,
        a.UseOrg,--������֯
		oo.Name UseOrgName,
        a.UseDept,--������
		dept.Code UseDeptCode,
		dept1.Name UseDeptName,		 
        a.UseMan,--������
		op.Code UseManCode,
		op1.Name UseManName,
        a.UsedTaxAC + a.IPVTaxAC Tax,--˰��
        a.NetUsedMnyAC + a.IPVAC NetMny,--δ˰�ɱ�        
        a.NetUsedMnyAC + a.IPVAC OrignalValue--ԭֵ=δ˰�ɱ�
--,a.IPVAC,a.IPVTaxAC,a.NetUsedMnyAC,a.UsedTaxAC,a.UsedMnyAC
FROM    dbo.PM_RcvLineDispense a
        LEFT JOIN dbo.PM_RcvLineDispense_Trl a1 ON a.ID = a1.ID
        LEFT JOIN dbo.PM_RcvLine b ON a.RcvLine = b.ID
        LEFT JOIN dbo.PM_Receivement c ON b.Receivement = c.ID
		LEFT JOIN dbo.CBO_Supplier sup ON c.Supplier_Supplier=sup.ID
		LEFT JOIN dbo.CBO_Supplier_Trl sup1 ON sup.ID=sup1.ID AND ISNULL(sup1.SysMLFlag,'zh-cn')='zh-cn'
        LEFT JOIN dbo.CBO_ItemMaster m ON b.ItemInfo_ItemID = m.ID
		LEFT JOIN dbo.Base_Organization o ON c.Org=o.ID
		LEFT JOIN dbo.CBO_Department dept ON a.UseDept=dept.ID
		LEFT JOIN dbo.CBO_Department_Trl dept1 ON dept.ID=dept1.ID AND ISNULL(dept1.SysMLFlag,'zh-cn')='zh-cn'
		LEFT JOIN dbo.CBO_Operators op ON a.UseMan=op.ID
		LEFT JOIN dbo.CBO_Operators_Trl op1 ON op.ID=op1.id AND isnull(op1.SysMLFlag,'zh-cn')='zh-cn'
		LEFT JOIN dbo.Base_Organization_Trl oo ON a.UseOrg=oo.ID
WHERE   a.[CanProcessQtyTU] > 0
        AND ISNULL(a.IsNotSetUpCard, 0) = 0
        AND b.SplitFlag != 1
        AND c.Status IN ( 4, 5 )
--AND c.Org=1001708020135665 
        AND c.ReceivementType = 0
        AND a.IPVAC != 0
        AND m.ItemFormAttribute = 18
        --AND a.ID = 1002001070009807;

		