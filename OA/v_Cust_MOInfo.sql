/*
工单信息视图
*/
ALTER VIEW v_Cust_MOInfo
AS

SELECT a.ID MOID,a.DocNo,b.Code,b.Name,dbo.F_GetEnumName('UFIDA.U9.MO.Enums.MOStateEnum',a.DocState,'zh-cn')DocState
,CONVERT(INT,a.ProductQty)ProductQty,d1.Name Dept,l.Name OriginalLineName
,CONVERT(VARCHAR(20),a.StartDate,23)OriginalStartDate
,CONVERT(VARCHAR(20),a.CompleteDate,23)OriginalCompleteDate
,a.Org OrgID,o.Code OrgCode,o1.Name OrgName
,so.DocNo SODocNo
,ISNULL(FORMAT(so.DeliveryDate,'yyyy-MM-dd'),a.DescFlexField_PrivateDescSeg5) SODeliveryDate
,a.DescFlexField_PrivateDescSeg4 SO
,mrp.Name MRPName
,ROW_NUMBER() OVER(PARTITION BY a.DocNo ORDER BY ISNULL(FORMAT(so.DeliveryDate,'yyyy-MM-dd'),a.DescFlexField_PrivateDescSeg5))RN
FROM dbo.MO_MO a  INNER JOIN dbo.CBO_ItemMaster b ON a.ItemMaster=b.ID
LEFT JOIN dbo.Base_Organization o ON a.Org=o.ID LEFT JOIN dbo.Base_Organization_Trl o1 ON o.id=o1.ID AND ISNULL(o1.SysMLFlag,'zh-cn')='zh-cn'
LEFT JOIN dbo.CBO_Department_Trl d1 ON a.Department=d1.ID AND ISNULL(d1.SysMLFlag,'zh-cn')='zh-cn'
LEFT JOIN (SELECT a.DocNo+'-'+CONVERT(VARCHAR(20),b.DocLineNo)+'-'+CONVERT(VARCHAR(20),c.DocSubLineNo)DocNo,c.DemandType,c.DeliveryDate,a.org
FROM dbo.SM_SO a INNER JOIN dbo.SM_SOLine b ON a.ID=b.SO
INNER JOIN dbo.SM_SOShipline c ON b.ID=c.SOLine ) so ON a.DemandCode=so.DemandType AND a.demandcode<>-1 AND so.Org=a.org
LEFT JOIN ( SELECT  A.[ID] as [ID], A.[Code] as [Code], A1.[Name] as [Name]
 FROM  Base_DefineValue as A  left join Base_Language as A2 on (A2.Code = 'zh-CN')
  and (A2.Effective_IsEffective = 1)  left join [Base_DefineValue_Trl] as A1 on (A1.SysMlFlag = 'zh-CN') and (A1.SysMlFlag = A2.Code) and (A.[ID] = A1.[ID])
   WHERE  (((A.[ValueSetDef] = (SELECT ID FROM Base_ValueSetDef WHERE code='ZDY_SCXB') ) and (A.[Effective_IsEffective] = 1)) and (A.[Effective_EffectiveDate] <= GETDATE())) 
   AND (A.[Effective_DisableDate] >= GETDATE())) L ON a.DescFlexField_PrivateDescSeg6=l.Code
LEFT JOIN dbo.vw_MRPCategory mrp ON b.DescFlexField_PrivateDescSeg22=mrp.Code
WHERE 1=1
AND a.cancel_canceled=0 AND a.org=(SELECT id FROM dbo.Base_Organization WHERE code='300')









GO
