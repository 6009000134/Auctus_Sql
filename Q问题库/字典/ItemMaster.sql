/*
料品档案MOQ\MPQ\采购周期同步到供应商料品价差表
*/

SELECT --TOP 10
a.ID
--,mrpC.Code MRPCode
,mrpc.Name MRP分类
,a.Code 料号
,a.Name
--,a.Name 品名
--,a.SPECS 规格
,cat.Code--财务分类编码
,cat1.Name 财务分类--财务分类
--,a.ItemForm--料品形态
,a.ItemForm--料品形态
,dbo.F_GetEnumName('UFIDA.U9.CBO.SCM.Item.ItemTypeEnum',a.ItemForm,'zh-cn')料品形态----料品形态
--,a.ItemFormAttribute--料品形态属性
,dbo.F_GetEnumName('UFIDA.U9.CBO.SCM.Item.ItemTypeAttributeEnum',a.ItemFormAttribute,'zh-cn')料品形态属性----料品形态属性
,a.DescFlexField_PrivateDescSeg1 TQC责任人
,op.Code SourcingCode
,op1.Name Sourcing
,op2.Code BuyerCode
,op21.Name Buyer
,op3.Code MCCode
,op31.Name MC
,CASE WHEN a.DescFlexField_PrivateDescSeg17='10' THEN '是' WHEN a.DescFlexField_PrivateDescSeg17='20' THEN'否' ELSE ''END 是否齐套考核
,CASE WHEN a.DescFlexField_PrivateDescSeg12='True'THEN '√' ELSE '' END 免检
,a.DescFlexField_PrivateDescSeg16 标准交期
,CASE WHEN a.DescFlexField_PrivateDescSeg30='10' THEN '是' WHEN a.DescFlexField_PrivateDescSeg30='20' THEN '否' ELSE'' END  物料状态
--,wh.Code 存储地点编码
,wh1.Name 存储地点
--,pick.Code 拣货规则编码
,pick.ID
,pick1.Name 拣货规则
--,put.Code
,put.ID
,put1.Name 理货规则
--,lot.Code
,lot.Name 批号参数
,p.MinRcvQty MOQ--MOQ
,p.PurchaseBatchQty MPQ--MPQ
,CASE WHEN p.IsReceiptSourceControl=1 THEN '√' ELSE '' END 进货货源管控
,CASE WHEN p.IsReturnSourceControl=1 THEN '√' ELSE '' END 退货货源管控
--,p.PriceSource
,dbo.F_GetEnumName('UFIDA.U9.CBO.SCM.Item.PurchasePriceSourceEnum',p.PriceSource,'zh-cn')取价来源
--,p.ReceiptMode--收货程序
,dbo.F_GetEnumName('UFIDA.U9.CBO.SCM.Supplier.ReceiptModeEnum',p.ReceiptMode,'zh-cn')收货程序
--,p.ReceiptModeAllowModify--收货程序可改
,p.ReceiptType
,dbo.F_GetEnumName('UFIDA.U9.CBO.SCM.Item.ReceiptTypeEnum',p.ReceiptType,'zh-cn')收货方式
--,p.ReceiptRule
,recr1.Name 收货原则
,CASE WHEN si.IsAvailableQtyCheck=1 THEN '√' ELSE '' END 可用量检查
--,si.AvailableQtyRule
,av1.Name 可用量规则
,CONVERT(INT,i.SafetyStockQty) 安全库存

,mrp.MRPPlanningType
,dbo.F_GetEnumName('UFIDA.U9.CBO.SCM.Item.MRPPlanningMethodEnum',mrp.MRPPlanningType,'zh-cn')计划方法
,CASE WHEN mrp.IsControlByDC=1 THEN '√' ELSE '' END 需求分类--是否需求分类号控制
--,mrp.DemandRule 
,dbo.F_GetEnumName('UFIDA.U9.CBO.SCM.Item.DemandRuleEnum',mrp.DemandRule,'zh-cn')需求分类规则
--,mrp.PurForwardProcessLT--	采购预提前期(天)
,mrp.PurProcessLT 采购处理提前期--采购处理提前期(天)
,mrp.PurBackwardProcessLT 采购后提前期--	采购后提前期(天)
,mrp.FixedLT 固定提前期--固定提前期(天)
--,mrp.LTBatch--	提前期批量
--,mrp.SumLT--汇总提前期(天)
,ce1.Name 成本要素
FROM dbo.CBO_ItemMaster a 
LEFT JOIN dbo.CBO_Operators op ON a.DescFlexField_PrivateDescSeg6=op.Code
LEFT JOIN dbo.CBO_Operators_Trl op1 ON op.ID=op1.ID AND op1.SysMLFlag='zh-cn'
LEFT JOIN dbo.CBO_Operators op2 ON a.DescFlexField_PrivateDescSeg23=op2.Code
LEFT JOIN dbo.CBO_Operators_Trl op21 ON op2.ID=op21.ID AND op21.SysMLFlag='zh-cn'
LEFT JOIN dbo.CBO_Operators op3 ON a.DescFlexField_PrivateDescSeg24=op3.Code
LEFT JOIN dbo.CBO_Operators_Trl op31 ON op3.ID=op31.ID AND op31.SysMLFlag='zh-cn'
LEFT JOIN dbo.CBO_Category cat ON a.AssetCategory=cat.ID LEFT JOIN dbo.CBO_Category_Trl cat1 ON cat.ID=cat1.ID AND cat1.SysMLFlag='zh-cn'
LEFT JOIN dbo.vw_MRPCategory mrpC ON a.DescFlexField_PrivateDescSeg22=mrpC.Code
INNER JOIN dbo.CBO_InventoryInfo i ON a.ID=i.ItemMaster
LEFT JOIN dbo.CBO_Wh wh ON i.Warehouse=wh.ID LEFT JOIN dbo.CBO_Wh_Trl wh1 ON wh.id=wh1.ID AND wh1.SysMLFlag='zh-cn'
LEFT JOIN dbo.CBO_PickBy pick ON i.PickingRule=pick.ID LEFT JOIN dbo.CBO_PickBy_Trl pick1 ON pick.id=pick1.id AND pick1.SysMLFlag='zh-cn'
LEFT JOIN CBO_TallyRule put ON i.PutawayRule=put.ID  LEFT JOIN dbo.CBO_TallyRule_Trl put1 ON put.id=put1.id AND put1.SysMLFlag='zh-cn'
LEFT JOIN dbo.CBO_LotParameter lot ON i.LotParam=lot.ID
INNER JOIN dbo.CBO_PurchaseInfo p ON a.ID=p.ItemMaster
LEFT JOIN CBO_ReceiptRule recr ON recr.ID=p.ReceiptRule LEFT JOIN dbo.CBO_ReceiptRule_Trl recr1 ON recr.ID=recr1.ID AND recr1.SysMLFlag='zh-cn'
LEFT JOIN CBO_SaleInfo si ON si.ItemMaster=a.ID
LEFT JOIN CBO_AvailableQtyRule av ON si.AvailableQtyRule=av.ID LEFT JOIN dbo.CBO_AvailableQtyRule_Trl av1 ON av.ID=av1.id AND av1.SysMLFlag='zh-cn'
INNER JOIN dbo.CBO_MrpInfo mrp ON a.ID=mrp.ItemMaster
LEFT JOIN CBO_MfgInfo mfg ON mfg.ItemMaster=a.ID
LEFT JOIN dbo.CBO_CostElement ce ON mfg.CostElement=ce.ID LEFT JOIN dbo.CBO_CostElement_Trl ce1 ON ce.ID=ce1.ID AND ce1.SysMLFlag='zh-cn'
WHERE a.org=(SELECT id FROM dbo.Base_Organization WHERE code='300')
AND a.Effective_IsEffective=1
--AND (a.Code LIKE '1%' OR a.Code LIKE '4%' OR a.Code LIKE '3%' OR a.Code LIKE '4%' OR a.Code LIKE 'S%')
--AND ( a.Code LIKE '4%' OR a.Code LIKE 'S%')
AND a.code LIKE '306011095%'
--AND cat1.Name!='原材料'
ORDER BY a.Code
--AND op1.Name='谌哲明' --sourcing  DescFlexField_PrivateDescSeg6
--AND op21.Name='谌哲明' --buyer  DescFlexField_PrivateDescSeg23
--AND op31.Name='谌哲明' --mc  DescFlexField_PrivateDescSeg24
--AND ISNULL(op21.Name,'')!=''
--sourcing
/*
UPDATE a SET a.DescFlexField_PrivateDescSeg6='301879'
FROM dbo.CBO_ItemMaster a 
WHERE a.DescFlexField_PrivateDescSeg6='302050' AND a.Org=(SELECT id FROM dbo.Base_Organization WHERE code='300')
*/
--buyer
/*
UPDATE a SET a.DescFlexField_PrivateDescSeg23='301879'
FROM dbo.CBO_ItemMaster a 
WHERE a.DescFlexField_PrivateDescSeg23='302050' AND a.Org=(SELECT id FROM dbo.Base_Organization WHERE code='300')
*/
--mc
/*
UPDATE a SET a.DescFlexField_PrivateDescSeg24='3013980'
FROM dbo.CBO_ItemMaster a 
WHERE a.DescFlexField_PrivateDescSeg24='3013984' AND a.Org=(SELECT id FROM dbo.Base_Organization WHERE code='300')
*/

--306011080