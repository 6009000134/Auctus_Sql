/*
资产卡片来源单据
*/
ALTER VIEW v_Cust_AssetSrcDoc4OA
as
SELECT  a.ID DispenseID ,--SourcDocLineID
        c.Org,
		o.Code OrgCode,
        c.DocNo SrcDoc ,--收货单号
        b.DocLineNo SrcDocLineNo ,--收货单行
		sup.ID SupplierID,
		sup.Code SupplierCode,
		sup1.Name SupplierName,
        m.Code,--料号
        m.Name,--品名
        m.ID ItemID ,
        a.CanProcessQtyTU ,
        a.UseOrg,--货主组织
		oo.Name UseOrgName,
        a.UseDept,--管理部门
		dept.Code UseDeptCode,
		dept1.Name UseDeptName,		 
        a.UseMan,--负责人
		op.Code UseManCode,
		op1.Name UseManName,
        a.UsedTaxAC + a.IPVTaxAC Tax,--税金
        a.NetUsedMnyAC + a.IPVAC NetMny,--未税成本        
        a.NetUsedMnyAC + a.IPVAC OrignalValue--原值=未税成本
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

		