/*
工单基础信息
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
            CONVERT(INT, a.ProductQty) ProductQty ,--工单数量
            mrp.Code MRPCode ,--MRP分类
            mrp.Name MRPName ,--MRP分类
            dept.ID DeptID ,--生产部门
            dept.Code DeptCode ,--生产部门
            dept1.Name DeptName ,--生产部门
            line.ID LineID ,--线别
            line.Code LineCode ,--线别
            line.Name LineName ,--线别
            a.Cancel_Canceled ,--0/1--正常/作废
            a.IsHoldRelease ,--0/1 -- 正常/挂起
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
