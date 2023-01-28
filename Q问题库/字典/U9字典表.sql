SELECT a.[FullName] as FullName,a.[Name] as Name,b.[DisplayName] as DisplayName,a.DefaultTableName  as DefaultTableName,
	    a.[ClassType] as ClassType,a.[ID] , c.AssemblyName
	    FROM [UBF_MD_Class] as a  
	    left join UBF_MD_Class_trl as b  on a.Local_ID=b.Local_ID
	    left join UBF_MD_Component as c on a.MD_Component_ID=c.ID
        where ClassType in(1,3)  and  ( b.sysmlflag='zh-CN' or b.sysmlflag is null ) 
         and (a.Name ='itemmaster' or  b.DisplayName ='itemmaster')  
		 ORDER by Name

	

 SELECT a.[Name] as Name, a.DataTypeID as ID,b.FullName as FullName, a.DefaultValue as DefaultValue ,
        a.IsCollection,c.DisplayName as DisplayName,c.[Description] as Description,
        b.ClassType  as ClassType  ,a.IsKey ,a.IsNullable ,a.IsReadOnly,a.IsSystem,a.IsBusinessKey,a.GroupName
        from UBF_MD_Attribute  a  
        inner join UBF_MD_CLASS b ON a.DataTypeID =b.ID  
        left join UBF_MD_Attribute_trl as c on a.Local_ID=c.Local_ID and ( c.sysmlflag='zh-CN' or c.sysmlflag is null ) 
        where a.MD_Class_ID= '636d3e47-48aa-47fc-aca4-e6322bce775b' order by a.IsSystem desc,a.GroupName asc , a.[Name] ASC
        
SELECT  a.[FullName] as FullName,a.[Name] as Name,b.[DisplayName] as DisplayName,a.DefaultTableName  as DefaultTableName,
	    a.[ClassType] as ClassType,a.[ID] , c.AssemblyName
	    FROM [UBF_MD_Class] as a  
	    left join UBF_MD_Class_trl as b  on a.Local_ID=b.Local_ID
	    left join UBF_MD_Component as c on a.MD_Component_ID=c.ID
        where ClassType in(1,3)  and  ( b.sysmlflag='zh-CN' or b.sysmlflag is null ) 
        and (a.Name ='dsinfo' or  b.DisplayName ='dsinfo')  
		ORDER by Name

SELECT  a.DataTypeID as ID,b.FullName as FullName, a.DefaultValue as DefaultValue ,
        a.IsCollection,a.[Name] as Name,c.DisplayName as DisplayName,c.[Description] as Description,
        b.ClassType  as ClassType  ,a.IsKey ,a.IsNullable ,a.IsReadOnly,a.IsSystem,a.IsBusinessKey,a.GroupName
        from UBF_MD_Attribute  a  
        inner join UBF_MD_CLASS b ON a.DataTypeID =b.ID
        left join UBF_MD_Attribute_trl as c on a.Local_ID=c.Local_ID AND ( c.sysmlflag='zh-CN' or c.sysmlflag is null )
        WHERE a.MD_Class_ID= 'DE6F3569-DC1C-4303-ADBF-957414F1C493' 
		ORDER BY a.IsSystem desc,a.GroupName asc , a.[Name] ASC
  
      
;
WITH TableInfo AS
(
		SELECT a.name TableName,c.name ColumnName
FROM sysobjects a inner JOIN sys.tables b ON a.id=b.object_id
inner JOIN syscolumns c ON a.id=c.id
LEFT JOIN systypes d ON c.xusertype=d.xusertype
WHERE a.type='u' AND a.name='MRP_DSInfo'
),
DicInfo AS
(
SELECT  a.DataTypeID as ID,b.FullName as FullName, a.DefaultValue as DefaultValue ,
        a.IsCollection,a.[Name] as Name,c.DisplayName as DisplayName,c.[Description] as Description,
        b.ClassType  as ClassType  ,a.IsKey ,a.IsNullable ,a.IsReadOnly,a.IsSystem,a.IsBusinessKey,a.GroupName
        from UBF_MD_Attribute  a  
        inner join UBF_MD_CLASS b ON a.DataTypeID =b.ID
        left join UBF_MD_Attribute_trl as c on a.Local_ID=c.Local_ID AND ( c.sysmlflag='zh-CN' or c.sysmlflag is null )
        WHERE a.MD_Class_ID= 'DE6F3569-DC1C-4303-ADBF-957414F1C493' 
		--ORDER BY a.IsSystem desc,a.GroupName asc , a.[Name] ASC
)
SELECT 
a.ColumnName+' '+b.DisplayName+','
FROM TableInfo a FULL JOIN DicInfo b ON a.ColumnName=b.Name
FOR XML PATH('')


SELECT ID ID,CreatedOn 创建时间,CreatedBy 创建人,ModifiedOn 修改时间,ModifiedBy 修改人,FactoryOrg 工厂组织,Org 组织,Item 料品,ItemVersion 料品版本,FromDegree 从等级,ToDegree 到等级,FromPotency 从成分,ToPotency 到成分,Warehouse 存储地点,Lot 批号,Supplier 厂牌,DSType 需求供应形态,DocNo 单号,DocVersion 版本,DocType 单据类型,LineNum 行号,PlanLineNum 计划行号,TradeBaseUOM 交易基准单位,TradeBaseQty 交易数量,StoreMainUOM 库存主单位,SMQty 数量,ReserveQty 预留数量,DemandDate 需求日期,IsFirm 锁定标识,Project 项目,Task 任务,DemandCode 需求分类,PreDemandLine 上阶需求行ID,PreItemOrg 上阶料品组织,PreItem 上阶料品,PreDocNo 上阶需求单号,PreDocVersion 版本,PreDocLineNum 上阶需求行号,PreDocPlanLineNum 行号,OwnerOrg 货主组织,PlanVersion 计划版本,Sub 替代标志,LotInValidDate 批号失效日期,SrcPCDocNo 来源单号,SrcPCLineNo 来源行号,SupplyType 供应类型,BeforeAdjustSMQty 调整前需求数量,BeforeAdjustDemandDate 调整前需求日期,Seiban 番号,SeibanCode 番号,NetQty 净数量,IsOptimized 是否为优化供应,IsFirmPlannedMO 是否为计划生产订单,IsSubcontract 是否委外,SrcShipLineNo 来源计划行号,BOMComponent BOM子项
FROM dbo.MRP_DSInfo

