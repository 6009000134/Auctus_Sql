/*
工单备料信息
*/
ALTER  VIEW v_cust_MOPickList
AS
    SELECT  a.ID MOID ,--工单ID
            a.DocNo ,--工单号
            a.Org ,
            b.ID LineID ,--备料行ID
            b.DocLineNO ,--备料行号
            b.ItemMaster ItemID ,
            m.Code ,
            m.Name ,
            m.SPECS ,
            b.ActualReqQty ,--实际需求量
            b.IssuedQty ,--已发料数量
            CONVERT(VARCHAR(20),b.ActualReqDate,23)ActualReqDate ,--实际需求日期
            CONVERT(VARCHAR(20),b.PlanReqDate,23)PlanReqDate ,--计划需求日期
            b.IssueStyle ,--发料方式
            b.SupplyWh ,--存储地点
            1 IsEdit
    FROM    dbo.MO_MO a
            INNER JOIN dbo.MO_MOPickList b ON a.ID = b.MO
            INNER JOIN dbo.CBO_ItemMaster m ON b.ItemMaster = m.ID
    WHERE   a.DocState IN ( 1, 2 );


	