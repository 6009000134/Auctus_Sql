/*
源数据 
*/
BEGIN--源数据
SELECT a.Code,CONVERT(DECIMAL(18,2),a.DescFlexField_PrivateDescSeg18)UPPH FROM dbo.CBO_ItemMaster a 
WHERE a.Org=(SELECT id FROM dbo.Base_Organization WHERE code='300')
AND ISNULL(a.DescFlexField_PrivateDescSeg18,'')<>''

--取已审核状态U9工单
DECLARE @Org BIGINT=(SELECT id FROM dbo.Base_Organization WHERE code='300')
;
WITH Places AS
(
SELECT  T.Code,T.Name
FROM    ( SELECT    A.[ID] AS [ID] ,
                    A.[Code] AS [Code] ,
                    A1.[Name] AS [Name] ,
                    A.[SysVersion] AS [SysVersion] ,
                    A.[ID] AS [MainID] ,
                    A2.[Code] AS SysMlFlag ,
                    ROW_NUMBER() OVER ( ORDER BY A.[Code] ASC, ( A.[ID] + 17 ) ASC ) AS rownum
          FROM      Base_DefineValue AS A
                    LEFT JOIN Base_Language AS A2 ON ( A2.Code = 'zh-CN' )
                                                     AND ( A2.Effective_IsEffective = 1 )
                    LEFT JOIN [Base_DefineValue_Trl] AS A1 ON ( A1.SysMLFlag = 'zh-CN' )
                                                              AND ( A1.SysMLFlag = A2.Code )
                                                              AND ( A.[ID] = A1.[ID] )
          WHERE     (A.[ValueSetDef] = 1001910160011306 )AND ( A.[Effective_IsEffective] = 1 )
        ) T
)
SELECT a.DocNo,b.Code,a.ProductQty,
(select u2.Name from dbo.ubf_sys_extenumvalue  u,dbo.ubf_sys_extenumtype  u1 ,dbo.ubf_sys_extenumvalue_trl u2 WHERE  u.extenumtype=u1.id and u.id=u2.id
and u1.code='UFIDA.U9.CBO.Enums.DemandCodeEnum' AND u.EValue=a.DemandCode) ERPSO
,d.OrderByQtyTU ERPQuantity,d.DescFlexField_PubDescSeg3 CustomerOrder
,ISNULL(e.Address_AddressA,'')Address1,ISNULL(f1.Name,'')Country
,p.Code SendPlaceCode,p.Name SendPlace,dept.Name Department
,d1.CustomerItemName
FROM dbo.MO_MO a INNER JOIN dbo.CBO_ItemMaster b ON a.ItemMaster=b.ID 
LEFT JOIN (SELECT shipLine.DemandType,shipLine.SOLine,shipLine.Org FROM dbo.SM_SOShipline shipLine WHERE shipLine.DemandType<>-1) c  ON a.DemandCode=c.DemandType  LEFT JOIN dbo.SM_SOLine d ON c.SOLine=d.ID LEFT JOIN dbo.SM_SOLine_Trl d1 ON d.ID=d1.ID AND ISNULL(d1.SysMLFlag,'zh-cn')='zh-cn'
LEFT JOIN Places p ON d.DescFlexField_PrivateDescSeg1=p.Code
LEFT JOIN dbo.SM_SOAddress e ON d.ID=e.SOLine AND e.Address_Owner=2--Address_Owner=2代表地址拥有者是收货客户位置
LEFT JOIN dbo.Base_Country f ON e.Address_Country=f.ID LEFT JOIN dbo.Base_Country_Trl f1 ON f.ID=f1.ID AND ISNULL(f1.SysMLFlag,'zh-cn')='zh-cn'
LEFT JOIN dbo.CBO_Department_Trl dept ON a.Department=dept.ID AND ISNULL(dept.SysMLFlag,'zh-cn')='zh-cn'
WHERE a.DocState in (1,2) AND PATINDEX('WMO%',a.DocNo)=0 AND PATINDEX('VMO%',a.DocNo)=0
AND ISNULL(c.Org,@Org)=@Org
AND a.Org=@Org

END--源数据


BEGIN--目标数据
--同步U9 UPPH到mes料品档案表
UPDATE dbo.mxqh_Material SET UPPH=CONVERT(DECIMAL(18,2),a.UPPH) FROM #TempTable a 
WHERE a.Code=dbo.mxqh_Material.MaterialCode
--同步U9 UPPH到mes旧料品档案表
UPDATE dbo.baMaterial SET UPPH=CONVERT(DECIMAL(18,2),a.UPPH) FROM #TempTable a 
WHERE a.Code=dbo.baMaterial.MaterialCode
AND ISNULL(a.UPPH,0)<>0

TRUNCATE TABLE mxqh_U9MO
INSERT INTO dbo.mxqh_U9MO
        ( CreatedDate,
		DocNo ,
          MaterialID ,
          MaterialCode ,
          MaterialName ,
          ProductQty ,
          ERPSO ,
          ERPQuantity ,
          CustomerOrder ,
          Address1 ,
          Country,
		  SendPlace,
		  SendPlaceCode,
		  Department
        )
SELECT GETDATE(),a.DocNo,b.ID,b.MaterialCode,b.MaterialName,a.ProductQty, a.ERPSO
,a.ERPQuantity,a.CustomerOrder
,a.Address1,a.Country,a.SendPlace,a.SendPlaceCode,a.Department
FROM #TempTable a INNER JOIN mxqh_Material b ON a.code=b.MaterialCode left JOIN dbo.mxqh_plAssemblyPlanDetail c ON a.DocNo=c.WorkOrder
WHERE isnull(c.Status,0)<>4
END 


