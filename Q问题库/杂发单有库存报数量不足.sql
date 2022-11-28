/*
使用“明细账（数量）”报表
1、确认有库存数量
2、对照存储地点
3、对照存储类型
4、对照批次号
5、检查是否有在途（核准中）的杂发、领料单占用库存但是未扣减

--料品未批号管控，但是库存是有批号的，杂发单上不填批号则会提示需求数量不足，需要启用批号管控在杂发单填上对应批号

*/

--可用量查看
SELECT 
--* 
a.Doc_EntityType,a.CreatedOn,a.CreatedBy,a.ModifiedOn, a.ModifiedBy,a.DocNo,a.DocLineNo,a.DocSLNo,a.ItemInfo_ItemName,a.ItemInfo_ItemCode
,a.Wh,a.LotID,a.DemandQty,a.SupplyQty,a.StoreQtySU,a.SupplyMainQty,a.StoreQtyCU
FROM InvTrans_AvailableMatch a
WHERE a.ItemInfo_ItemCode='202010698'