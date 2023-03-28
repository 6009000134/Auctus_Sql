--MRP��������
SELECT  n.PlanCode ,
        M.Code ,
		dbo.F_GetEnumName('UFIDA.U9.MRP.Enums.DSInfoDocTypeEnum',a.DocType,'zh-cn')����,
		dbo.F_GetEnumName('UFIDA.U9.MRP.Enums.PlanOrderTypeEnum',a.SupplyType,'zh-cn') ��Ӧ����,		
        a.*
FROM    MRP_DSInfo a
        LEFT JOIN dbo.MRP_PlanVersion b ON a.PlanVersion = b.ID
        LEFT JOIN dbo.MRP_PlanName n ON b.PlanName = n.ID
        LEFT JOIN dbo.CBO_ItemMaster M ON a.Item = M.ID
WHERE   n.PlanCode = '30-MRP'-- AND a.OriginalDocHeader_EntityID=1002211140826898
ORDER BY a.SupplyType

--SELECT * FROM dbo.PM_PurchaseOrder WHERE id=1002211140826898


