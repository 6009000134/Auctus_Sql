
         SELECT a.MD_Class_ID,a.[Name] AS Name ,
                a.DataTypeID AS ID ,
                b.FullName AS FullName ,
                a.DefaultValue AS DefaultValue ,
                a.IsCollection ,
                c.DisplayName AS DisplayName ,
                c.[Description] AS Description ,
                b.ClassType AS ClassType ,
                a.IsKey ,
                a.IsNullable ,
                a.IsReadOnly ,
                a.IsSystem ,
                a.IsBusinessKey ,
                a.GroupName
         FROM   UBF_MD_Attribute a
                INNER JOIN UBF_MD_CLASS b ON a.DataTypeID = b.ID
                LEFT JOIN UBF_MD_Attribute_trl AS c ON a.Local_ID = c.Local_ID
                                                       AND ( c.sysmlflag = 'zh-CN'
                                                             OR c.sysmlflag IS NULL
                                                           )
         WHERE  MD_Class_ID = '26E495EC-D51F-488A-AF60-494A0ABD8B20'
         ORDER BY a.IsSystem DESC ,
                a.GroupName ASC ,
                a.[Name] ASC;


				SELECT * FROM UBF_MD_CLASS_trl a WHERE a.DisplayName='Éú²ú¶©µ¥'
				SELECT TOP 12 * FROM UBF_MD_CLASS a WHERE a.Local_ID=1001101172953160


				SELECT  * FROM dbo.UBF_MD_Attribute a INNER JOIN dbo.UBF_MD_Attribute_Trl b ON a.Local_ID=b.Local_ID AND a.DataTypeID='D81BF969-9BA9-423C-9FF2-C88537164C41'