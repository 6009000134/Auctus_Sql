SELECT mrp3.Name MRP����,a.MasterCode ���ϼ�BOM,mrp.Name MRP����,a.ParentCode ĸ���Ϻ�,mrp2.Name �Ӽ�MRP����,a.Code �Ӽ��Ϻ�,a.Sequence,a.SubSeq,a.IssueStyle ���Ϸ�ʽ,CASE WHEN a.ComponentType=0 THEN '��׼' ELSE '���' END �Ӽ�����,CASE WHEN a.IsPhantomPart=0 THEN '' ELSE '����' END ����
FROM dbo.Auctus_NewestBom a LEFT JOIN dbo.CBO_ItemMaster m ON a.PID=m.ID LEFT JOIN dbo.CBO_ItemMaster m1 ON a.MID=m1.ID
LEFT JOIN dbo.CBO_ItemMaster mm ON a.MasterCode=mm.Code AND mm.Org=(SELECT id FROM dbo.Base_Organization WHERE code='300')
LEFT JOIN dbo.vw_MRPCategory mrp ON m.DescFlexField_PrivateDescSeg22=mrp.Code LEFT JOIN dbo.vw_MRPCategory mrp2 ON m1.DescFlexField_PrivateDescSeg22=mrp2.Code
LEFT JOIN dbo.vw_MRPCategory mrp3 ON mm.DescFlexField_PrivateDescSeg22=mrp3.Code
WHERE m.DescFlexField_PrivateDescSeg22 IN ('MRP100','MRP101','MRP102','MRP103','MRP107','MRP115','MRP116','MRP117','MRP118','MRP119')
AND m1.DescFlexField_PrivateDescSeg22 IN ('MRP100','MRP101','MRP102','MRP103','MRP107','MRP115','MRP116','MRP117','MRP118','MRP119')
ORDER BY a.MasterCode,a.Level,a.ParentCode,a.Code

--SELECT TOP 10 * FROM dbo.Auctus_NewestBom
--SELECT TOP 10 * FROM dbo.Auctus_NewestBomMonth

