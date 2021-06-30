/*
����������Ϣ
*/
ALTER VIEW v_cust_MOBaseInfo4OA
AS
    SELECT  a.ID ,
            a.DocNo ,
            doctype.Code DocType ,
            doctype1.Name DocTypeName ,
            a.Org ,
            b.Code ,
            b.Name ,
            b.SPECS ,
            CONVERT(INT, a.ProductQty) ProductQty ,--��������
            mrp.Code MRPCode ,--MRP����
            mrp.Name MRPName ,--MRP����
            dept.ID DeptID ,--��������
            dept.Code DeptCode ,--��������
            dept1.Name DeptName ,--��������
            line.ID LineID ,--�߱�
            line.Code LineCode ,--�߱�
            line.Name LineName ,--�߱�
            a.Cancel_Canceled ,--0/1--����/����
            a.IsHoldRelease ,--0/1 -- ����/����
            a.DocState ,
            dbo.F_GetEnumName('UFIDA.U9.MO.Enums.MOStateEnum', a.DocState,
                              'zh-cn') DocStateName
    FROM    dbo.MO_MO a
            INNER JOIN dbo.CBO_ItemMaster b ON a.ItemMaster = b.ID
            LEFT JOIN dbo.vw_MRPCategory mrp ON b.DescFlexField_PrivateDescSeg22 = mrp.Code
            LEFT JOIN dbo.CBO_Department dept ON a.Department = dept.ID
            LEFT JOIN dbo.CBO_Department_Trl dept1 ON dept.ID = dept1.ID
            LEFT JOIN ( SELECT  *
                        FROM    dbo.v_Cust_KeyValue
                        WHERE   GroupCode = 'ZDY_SCXB'
                      ) line ON line.Code = a.DescFlexField_PrivateDescSeg6
            LEFT JOIN dbo.MO_MODocType doctype ON a.MODocType = doctype.ID
            LEFT JOIN dbo.MO_MODocType_Trl doctype1 ON doctype.ID = doctype1.ID;
