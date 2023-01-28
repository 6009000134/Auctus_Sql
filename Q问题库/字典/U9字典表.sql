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


SELECT ID ID,CreatedOn ����ʱ��,CreatedBy ������,ModifiedOn �޸�ʱ��,ModifiedBy �޸���,FactoryOrg ������֯,Org ��֯,Item ��Ʒ,ItemVersion ��Ʒ�汾,FromDegree �ӵȼ�,ToDegree ���ȼ�,FromPotency �ӳɷ�,ToPotency ���ɷ�,Warehouse �洢�ص�,Lot ����,Supplier ����,DSType ����Ӧ��̬,DocNo ����,DocVersion �汾,DocType ��������,LineNum �к�,PlanLineNum �ƻ��к�,TradeBaseUOM ���׻�׼��λ,TradeBaseQty ��������,StoreMainUOM �������λ,SMQty ����,ReserveQty Ԥ������,DemandDate ��������,IsFirm ������ʶ,Project ��Ŀ,Task ����,DemandCode �������,PreDemandLine �Ͻ�������ID,PreItemOrg �Ͻ���Ʒ��֯,PreItem �Ͻ���Ʒ,PreDocNo �Ͻ����󵥺�,PreDocVersion �汾,PreDocLineNum �Ͻ������к�,PreDocPlanLineNum �к�,OwnerOrg ������֯,PlanVersion �ƻ��汾,Sub �����־,LotInValidDate ����ʧЧ����,SrcPCDocNo ��Դ����,SrcPCLineNo ��Դ�к�,SupplyType ��Ӧ����,BeforeAdjustSMQty ����ǰ��������,BeforeAdjustDemandDate ����ǰ��������,Seiban ����,SeibanCode ����,NetQty ������,IsOptimized �Ƿ�Ϊ�Ż���Ӧ,IsFirmPlannedMO �Ƿ�Ϊ�ƻ���������,IsSubcontract �Ƿ�ί��,SrcShipLineNo ��Դ�ƻ��к�,BOMComponent BOM����
FROM dbo.MRP_DSInfo

