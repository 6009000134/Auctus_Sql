

/*
mxqh_plAssemblyPlan
*/
----�������� mxqh_plAssemblyPlan
--SET IDENTITY_INSERT mxqh_plAssemblyPlan ON
--INSERT INTO dbo.mxqh_plAssemblyPlan
--        ( ID,CreateBy ,
--          CreateDate ,
--          ModifyBy ,
--          ModifyDate ,
--          AssemblyDate ,
--          AssemblyLineID ,
--          AssemblyLineCode ,
--          AssemblyLineName ,
--          VesionNo
--        )
--		SELECT a.ID,'SSAdmin',a.TS,'SSAdmin',a.TS,a.AssemblyDate,a.AssemblyLineID,a.AssemblyLineCode,a.AssemblyLineName,a.VesionNo FROM dbo.plAssemblyPlan a
--SET IDENTITY_INSERT mxqh_plAssemblyPlan OFF
/*
mxqh_plAssemblyPlanDetail
*/
--����ExtendOne�ֶβ�����DateTime��ʽ�����ݲ����޸�
--SELECT * FROM dbo.mxqh_plAssemblyPlanDetail
--SELECT a.ID,a.ExtendOne FROM dbo.plAssemblyPlanDetail a WHERE ISDATE(a.ExtendOne)=0 AND ISNULL(a.ExtendOne,'')<>''
--UPDATE dbo.plAssemblyPlanDetail SET ExtendOne='2018-09-27 08:30:32.000' WHERE dbo.plAssemblyPlanDetail.ID IN 
--(SELECT a.ID FROM dbo.plAssemblyPlanDetail a WHERE ISDATE(a.ExtendOne)=0 AND ISNULL(a.ExtendOne,'')<>'')

----��������
--SET IDENTITY_INSERT dbo.mxqh_plAssemblyPlanDetail ON
----δ�깤������ͳһStatus=0
--INSERT INTO dbo.mxqh_plAssemblyPlanDetail
--        ( ID,CreateBy ,CreateDate ,ModifyBy ,ModifyDate ,AssemblyPlanID ,ListNo ,
--          WorkOrder ,
--          MaterialID ,MaterialCode ,MaterialName ,
--          Quantity ,
--          OnlineTime ,
--          OfflineTime ,
--          CustomerOrder ,
--          DeliveryDate ,
--          CustomerID ,CustomerCode ,CustomerName ,SendPlaceID ,SendPlaceCode ,SendPlaceName ,
--          IsPublish ,IsLock ,Status ,
--          CompleteDate ,
--          ERPSO ,ERPMO ,ERPQuantity ,ERPOrderNo ,ERPOrderQty ,
--          --IsUpload ,
--          boRoutingID ,
--          TBName ,
--          CLName
--        )
--		SELECT a.ID,'SSAdmin',a.TS,'SSAdmin',a.TS,a.AssemblyPlanID,a.ListNo,a.WorOrder,a.MaterialID,a.MaterialCode,a.MaterialName 
--		,a.Quantity,a.OnlineTime,a.OfflineTime,a.CustomerOrder,a.DeliveryDate,a.CustomerID,a.CustomerCode,a.CustomerName,a.SendPlaceID
--		,a.SendPlaceCode,a.SendPlaceName,a.IsPublish,a.IsLock
--		,CASE WHEN ISNULL(a.ExtendOne,'')='' THEN  0 ELSE 4 END --δ�깤��Status=0���깤��Status=4
--		,a.ExtendOne,a.ERPSO,a.ERPMO,a.ERPQuantity,a.ERPOrderNo,a.ERPOrderQty--,a.IsUpload
--		,NULL,'',''
--		FROM dbo.plAssemblyPlanDetail a 

--SET IDENTITY_INSERT dbo.mxqh_plAssemblyPlanDetail OFF

