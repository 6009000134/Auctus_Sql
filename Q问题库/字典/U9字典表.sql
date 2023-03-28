DECLARE @Name VARCHAR(100)='ItemMaster',@DisPlayName VARCHAR(100)=''
,@ColName VARCHAR(100)='ItemFormAttribute'
,@ColDisplayName VARCHAR(100)
--表格信息
SELECT a.[FullName] as FullName,a.[Name] as Name,b.[DisplayName] as DisplayName,a.DefaultTableName  as DefaultTableName,
	    a.[ClassType] as ClassType,a.[ID] , c.AssemblyName
	    FROM [UBF_MD_Class] as a  
	    left join UBF_MD_Class_trl as b  on a.Local_ID=b.Local_ID
	    left join UBF_MD_Component as c on a.MD_Component_ID=c.ID
        where ClassType in(1,3)  and  ( b.sysmlflag='zh-CN' or b.sysmlflag is null ) 
         and (a.Name =@Name or  b.DisplayName =@DisPlayName)  
		 ORDER by Name

--字段信息
SELECT a.[Name] as Name, a.DataTypeID as ID,b.FullName as FullName, a.DefaultValue as DefaultValue ,
        a.IsCollection,c.DisplayName as DisplayName,c.[Description] as Description,
        b.ClassType  as ClassType  ,a.IsKey ,a.IsNullable ,a.IsReadOnly,a.IsSystem,a.IsBusinessKey,a.GroupName
        from UBF_MD_Attribute  a  
        inner join UBF_MD_CLASS b ON a.DataTypeID =b.ID  
        left join UBF_MD_Attribute_trl as c on a.Local_ID=c.Local_ID and ( c.sysmlflag='zh-CN' or c.sysmlflag is null ) 
        where a.MD_Class_ID=(
		SELECT a.[ID]
	    FROM [UBF_MD_Class] as a  
	    left join UBF_MD_Class_trl as b  on a.Local_ID=b.Local_ID
	    left join UBF_MD_Component as c on a.MD_Component_ID=c.ID
        where ClassType in(1,3)  and  ( b.sysmlflag='zh-CN' or b.sysmlflag is null ) 
         and (a.Name =@Name or  b.DisplayName =@DisPlayName)  
		)
--字段详情
SELECT a.[Name] as Name, a.DataTypeID as ID,b.FullName as FullName, a.DefaultValue as DefaultValue ,
        a.IsCollection,c.DisplayName as DisplayName,c.[Description] as Description,
        b.ClassType  as ClassType  ,a.IsKey ,a.IsNullable ,a.IsReadOnly,a.IsSystem,a.IsBusinessKey,a.GroupName
        from UBF_MD_Attribute  a  
        inner join UBF_MD_CLASS b ON a.DataTypeID =b.ID  
        left join UBF_MD_Attribute_trl as c on a.Local_ID=c.Local_ID and ( c.sysmlflag='zh-CN' or c.sysmlflag is null ) 
		WHERE a.MD_Class_ID IN (
SELECT  a.DataTypeID
        from UBF_MD_Attribute  a  
        inner join UBF_MD_CLASS b ON a.DataTypeID =b.ID  
        left join UBF_MD_Attribute_trl as c on a.Local_ID=c.Local_ID and ( c.sysmlflag='zh-CN' or c.sysmlflag is null ) 
        where a.MD_Class_ID=(
		SELECT a.[ID]
	    FROM [UBF_MD_Class] as a  
	    left join UBF_MD_Class_trl as b  on a.Local_ID=b.Local_ID
	    left join UBF_MD_Component as c on a.MD_Component_ID=c.ID
        where ClassType in(1,3)  and  ( b.sysmlflag='zh-CN' or b.sysmlflag is null ) 
         and (a.Name =@Name or  b.DisplayName =@DisPlayName)  
		)
		AND a.Name=@ColName		
		)



		
--生成表格查询sql      
--;
--WITH TableInfo AS
--(
--SELECT a.name TableName,c.name ColumnName
--FROM sysobjects a inner JOIN sys.tables b ON a.id=b.object_id
--inner JOIN syscolumns c ON a.id=c.id
--LEFT JOIN systypes d ON c.xusertype=d.xusertype
--WHERE a.type='u' AND a.name='PM_POShipLine'
--),
--DicInfo AS
--(
--SELECT  a.DataTypeID as ID,b.FullName as FullName, a.DefaultValue as DefaultValue ,
--        a.IsCollection,a.[Name] as Name,c.DisplayName as DisplayName,c.[Description] as Description,
--        b.ClassType  as ClassType  ,a.IsKey ,a.IsNullable ,a.IsReadOnly,a.IsSystem,a.IsBusinessKey,a.GroupName
--        from UBF_MD_Attribute  a  
--        inner join UBF_MD_CLASS b ON a.DataTypeID =b.ID
--        left join UBF_MD_Attribute_trl as c on a.Local_ID=c.Local_ID AND ( c.sysmlflag='zh-CN' or c.sysmlflag is null )
--        WHERE a.MD_Class_ID= '6384535C-00E2-47D3-828B-06096D2AC8D8' 
--		--ORDER BY a.IsSystem desc,a.GroupName asc , a.[Name] ASC
--)
--SELECT 
--a.ColumnName+' '+b.DisplayName+','
--FROM TableInfo a FULL JOIN DicInfo b ON a.ColumnName=b.Name
--WHERE a.ColumnName NOT LIKE 'DescFlexSegments%'
--FOR XML PATH('')


