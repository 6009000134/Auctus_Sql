/*
研发入库记录扫码
*/
ALTER PROC [dbo].[sp_TP_RDRcvScan]
(
@pageIndex INT,
@pageSize INT,
@SNCode VARCHAR(100),
@RcvID INT,
@DocType VARCHAR(100),
@Progress VARCHAR(10),--样机阶段
@Status VARCHAR(10),--样机状态
@MaterialID INT,
@Remark NVARCHAR(2000),
@CreateBy VARCHAR(100),
@IsSN BIT
)
AS
BEGIN
	--DECLARE @SNCode VARCHAR(100)='123',@TestRecordID INT=3
	DECLARE @beginIndex INT=@pageSize*(@pageIndex-1)
	DECLARE @endIndex INT=@pageSize*@pageIndex+1	
	IF @IsSN='true'--输入的是SN编码
	BEGIN
		IF	@DocType='旧料入库'--判断是否入库过，无入库记录则直接入库
		BEGIN
			IF EXISTS(SELECT 1 FROM dbo.TP_RDRcvDetail a WHERE a.SNCode=@SNCode)
			BEGIN
						--判断当前SN编码属于是否在库
						IF EXISTS(SELECT 1 FROM (
							SELECT t.*,ROW_NUMBER()OVER(ORDER BY t.CreateDate DESC)RN FROM (
							SELECT a.CreateDate,a.SNCode,1 IsRcv FROM dbo.TP_RDRcvDetail a 
							WHERE a.SNCode=@SNCode
							UNION ALL
							SELECT a.CreateDate,a.SNCode,0 IsRcv FROM dbo.TP_RDShipDetail a
							WHERE a.InternalCode=@SNCode
							) t ) t WHERE t.RN=1 AND t.IsRcv=1
							)
							BEGIN
								SELECT '0'MsgType,'['+@SNCode+']已经在'+(SELECT rcv.DocNo FROM (
								SELECT a.RcvID,a.SNCode,ROW_NUMBER()OVER(ORDER BY a.CreateDate desc)RN FROM dbo.TP_RDRcvDetail a WHERE a.SNCode=@SNCode)
								t INNER JOIN dbo.TP_RDRcv rcv ON t.RcvID=rcv.ID WHERE t.RN=1)+'内扫描过！'Msg		
								RETURN;
							END 
			END 
				SELECT '1'MsgType,'['+@SNCode+']扫码成功！'Msg
				INSERT INTO dbo.TP_RDRcvDetail
					( CreateBy ,
					  CreateDate ,
					  RcvID ,
					  InternalCode,
					  SNCode ,
					  MaterialID ,
					  MaterialCode ,
					  MaterialName ,
					  Status ,
					  Progress ,
					  Remark
					)			
				SELECT @CreateBy,GETDATE(),@RcvID,NULL,@SNCode,@MaterialID,c.MaterialCode,c.MaterialName,@Status,@Progress,@Remark 
				FROM dbo.mxqh_Material c
				WHERE c.ID=@MaterialID
		
				--返回扫码集合
				SELECT * 		
				FROM (
				SELECT a.ID,a.InternalCode,a.SNCode,a.Status,a.Progress,b.MaterialCode,b.MaterialName,a.Remark,ROW_NUMBER()OVER(ORDER BY a.CreateDate DESC)RN
				FROM dbo.TP_RDRcvDetail a INNER JOIN dbo.mxqh_Material b ON a.MaterialID=b.Id WHERE a.RcvID=@RcvID
				) t WHERE t.RN>@beginIndex AND t.RN<@endIndex

				SELECT (SELECT COUNT(1) FROM dbo.TP_RDRcvDetail a where a.RcvID=@RcvID)RcvCount
				RETURN ;
		END 


		--根据码查出内控码\SN编码
		DECLARE @BSN VARCHAR(100),@SN VARCHAR(100)
		/*
		1、bsn表获取数据
		2、包装是否有
		3、组装是否有
		*/		
		--从mes SN/BSN码关系表查找
		IF ISNULL(@BSN,'')='' AND ISNULL(@SN,'')=''
		BEGIN
			SELECT @BSN=ISNULL(a.InternalCode,''),@SN=ISNULL(a.SNCode,'') FROM dbo.vw_baInternalAndSNCode a WHERE a.SNCode=@SNCode OR a.InternalCode=@SNCode
		END 

		DECLARE @SNType INT=2--0包装、1组装、2、旧料入库
		--判断是组装还是包装数据
		IF ISNULL(@BSN,'')!='' OR ISNULL(@SN,'')!=''
		BEGIN
			IF EXISTS(SELECT 1 FROM dbo.vw_opPackageChild WHERE SNCode=@SN)			
			BEGIN
				SET @SNType=0
			END 
			ELSE IF EXISTS(SELECT 1 FROM dbo.vw_opPlanExecutMain WHERE InternalCode=@BSN)
			BEGIN
				SET @SNType=1
			END	
            ELSE
            BEGIN
				SET @SNType=2		
			END 
		END
		--SELECT TOP 11 * FROM opPackageChild
		--若SN码被解绑过，那么SN/BSN码关系表数据都会被删，此时查询包装表
		IF	ISNULL(@BSN,'')='' AND ISNULL(@SN,'')=''
		BEGIN
			SELECT @SN=ISNULL(a.SNCode,'') FROM dbo.vw_opPackageChild a WHERE a.SNCode=@SNCode		
			SET @SNType=0
		END
		--若SN码被解绑过，那么SN/BSN码关系表数据都会被删，此时查询组装表
		IF	ISNULL(@BSN,'')='' AND ISNULL(@SN,'')=''
		BEGIN
			SELECT @BSN=ISNULL(a.InternalCode,'') FROM dbo.vw_opPlanExecutMain a WHERE a.InternalCode=@SNCode		
			SET @SNType=1
		END

		--从入库记录中抓取编码信息
		IF	ISNULL(@BSN,'')='' AND ISNULL(@SN,'')=''
		BEGIN
			SELECT @BSN=ISNULL(a.InternalCode,''),@SN=ISNULL(a.SNCode,'') FROM dbo.TP_RDRcvDetail a WHERE ISNULL(a.SNCode,'')=@SNCode OR ISNULL(a.InternalCode,'')=@SNCode
			SET @SNType=2
		END		


		IF ISNULL(@BSN,'')=''  AND ISNULL(@SN,'')=''
		BEGIN
			SELECT '0'MsgType,'Mes中找不到['+@SNCode+']信息！'Msg
			RETURN;
		END 
		
		--@BSN不为空判断SN码是否已经在本单扫描过
		IF EXISTS(SELECT 1 FROM dbo.TP_RDRcvDetail a WHERE a.RcvID=@RcvID AND ISNULL(a.InternalCode,'')=ISNULL(@BSN,'') AND ISNULL(a.SNCode,'')=ISNULL(@SN,''))
		BEGIN
			SELECT '0'MsgType,'['+@SNCode+']已经在本单内扫描过！'Msg	
			RETURN;
		END 

		--判断当前SN编码属于是否在库
		IF EXISTS(SELECT 1 FROM (
		SELECT t.*,ROW_NUMBER()OVER(ORDER BY t.CreateDate DESC)RN FROM (
		SELECT a.CreateDate,a.SNCode,1 IsRcv FROM dbo.TP_RDRcvDetail a 
		WHERE ISNULL(a.InternalCode,'')=@BSN AND ISNULL(a.SNCode,'')=ISNULL(@SN,'')
		UNION ALL
		SELECT a.CreateDate,a.SNCode,0 IsRcv FROM dbo.TP_RDShipDetail a
		WHERE ISNULL(a.InternalCode,'')=@BSN AND ISNULL(a.SNCode,'')=ISNULL(@SN,'')
		) t ) t WHERE t.RN=1 AND t.IsRcv=1
		)
		BEGIN		
			SELECT '0'MsgType,'['+@SNCode+']已经在'+(SELECT rcv.DocNo FROM (
			SELECT a.RcvID,a.SNCode,ROW_NUMBER()OVER(ORDER BY a.CreateDate desc)RN FROM dbo.TP_RDRcvDetail a WHERE ISNULL(a.InternalCode,'')=@BSN AND ISNULL(a.SNCode,'')=@SN)
			t INNER JOIN dbo.TP_RDRcv rcv ON t.RcvID=rcv.ID WHERE t.RN=1)+'内扫描过！'Msg		
			RETURN;
		END 
		ELSE
			BEGIN
			IF @SNType=0--包装
			BEGIN
					INSERT INTO dbo.TP_RDRcvDetail
						( CreateBy ,
						  CreateDate ,
						  RcvID ,
						  InternalCode,
						  SNCode ,
						  MaterialID ,
						  MaterialCode ,
						  MaterialName ,
						  Status ,
						  Progress ,
						  Remark,
						  HardwareVersion,
						  SoftwareVersion,
						  AssemblyDate,
						  PackDate
						)			
					SELECT @CreateBy,GETDATE(),@RcvID,@BSN,@SN,b.MaterialID,c.MaterialCode,c.MaterialName,@Status,@Progress,@Remark 
						,(SELECT d.U9_BOMVersion FROM dbo.vw_opPackageChild a ,opPackageDetail b ,opPackageMain c,dbo.mxqh_plAssemblyPlanDetail d WHERE a.SNCode=ISNULL(@SN,'') AND a.PackDetailID=b.ID AND b.PackMainID=c.ID AND c.AssemblyPlanDetailID=d.id)
					,(SELECT t.SoftVersion FROM (SELECT a.SoftVersion,ROW_NUMBER()OVER(ORDER BY a.LogTime desc ) RN  
					FROM dbo.atetest a WHERE a.IsUse=1 AND a.BSN=ISNULL(@BSN,'') ) t WHERE t.RN=1)
					,(SELECT a.TS FROM dbo.vw_opPlanExecutMain a WHERE InternalCode=ISNULL(@BSN,'') )
					,(SELECT a.TS FROM dbo.vw_opPackageChild a WHERE a.SNCode=ISNULL(@SN,'') )
					FROM dbo.vw_opPackageChild a INNER JOIN dbo.opPackageDetail detail ON a.PackDetailID=detail.ID
					INNER JOIN dbo.opPackageMain m ON detail.PackMainID=m.ID INNER JOIN dbo.mxqh_plAssemblyPlanDetail b ON m.AssemblyPlanDetailID=b.ID
					INNER JOIN dbo.mxqh_Material c ON b.MaterialID=c.Id
					WHERE a.SNCode=@SN
					SELECT '1'MsgType,'['+@SNCode+']扫码成功！'Msg
			END 
			ELSE IF @SNType=1 --组装
			BEGIN					
				--判断是否完工
				IF EXISTS( 
					SELECT 1 FROM
					(
					SELECT ROW_NUMBER()OVER(PARTITION BY a.InternalCode,a.ID ORDER BY c.OrderNum DESC,ISNULL(c.PassTime,FORMAT(GETDATE(),'yyyy-MM-dd HH:mm:ss')))RN,c.IsPass
					FROM dbo.vw_opPlanExecutMain a INNER JOIN dbo.vw_opPlanExecutDetail c ON a.ID=c.PlanExecutMainID
					WHERE c.ExtendOne=0 AND a.InternalCode=@BSN
					) t WHERE t.RN=1 AND t.IsPass=1
				)
				BEGIN
					INSERT INTO dbo.TP_RDRcvDetail
						( CreateBy ,
						  CreateDate ,
						  RcvID ,
						  InternalCode,
						  SNCode ,
						  MaterialID ,
						  MaterialCode ,
						  MaterialName ,
						  Status ,
						  Progress ,
						  Remark,
						  HardwareVersion,
						  SoftwareVersion,
						  AssemblyDate,
						  PackDate
						)			
					SELECT @CreateBy,GETDATE(),@RcvID,@BSN,@SN,b.MaterialID,c.MaterialCode,c.MaterialName,@Status,@Progress,@Remark 
					,(SELECT d.U9_BOMVersion FROM dbo.vw_opPlanExecutMain a ,dbo.mxqh_plAssemblyPlanDetail d WHERE a.InternalCode=ISNULL(@BSN,'')AND a.AssemblyPlanDetailID=d.id)
					,(SELECT t.SoftVersion FROM (SELECT a.SoftVersion,ROW_NUMBER()OVER(ORDER BY a.LogTime desc ) RN  
					FROM dbo.atetest a WHERE a.IsUse=1 AND a.BSN=ISNULL(@BSN,'') ) t WHERE t.RN=1)
					,(SELECT a.TS FROM dbo.vw_opPlanExecutMain a WHERE InternalCode=ISNULL(@BSN,'') )
					,(SELECT a.TS FROM dbo.vw_opPackageChild a WHERE a.SNCode=ISNULL(@SN,'') )
					FROM dbo.vw_opPlanExecutMain a INNER JOIN dbo.mxqh_plAssemblyPlanDetail b ON a.AssemblyPlanDetailID=b.ID
					INNER JOIN dbo.mxqh_Material c ON b.MaterialID=c.Id
					WHERE a.InternalCode=@BSN
					SELECT '1'MsgType,'['+@SNCode+']扫码成功！'Msg
				END 
				ELSE
                BEGIN
					SELECT '0'MsgType,'['+@SNCode+']未完工！'Msg
					RETURN;
				END 
			END 
			ELSE--旧料入库
            BEGIN
					IF EXISTS(SELECT 1 FROM dbo.TP_RDRcvDetail a WHERE ISNULL(a.SNCode,'')=@SNCode OR ISNULL(a.InternalCode,'')=@SNCode)		
					BEGIN
					INSERT INTO dbo.TP_RDRcvDetail
						( CreateBy ,
						  CreateDate ,
						  RcvID ,
						  InternalCode,
						  SNCode ,
						  MaterialID ,
						  MaterialCode ,
						  MaterialName ,
						  Status ,
						  Progress ,
						  Remark,
						  HardwareVersion,
						  SoftwareVersion,
						  AssemblyDate,
						  PackDate
						)		
					SELECT TOP 1 @CreateBy,GETDATE(),@RcvID,@BSN,@SN,a.MaterialID,c.MaterialCode,c.MaterialName,@Status,@Progress,@Remark 
					,a.HardwareVersion,a.SoftwareVersion,a.AssemblyDate,a.PackDate
					FROM dbo.TP_RDRcvDetail a
					INNER JOIN dbo.mxqh_Material c ON a.MaterialID=c.Id
					WHERE ISNULL(a.InternalCode,'')=@BSN AND ISNULL(a.SNCode,'')=@SN
					SELECT '1'MsgType,'['+@SNCode+']扫码成功！'Msg
					END 
			END 

			--返回扫码集合
			SELECT * 		
			FROM (
			SELECT a.ID,a.InternalCode,a.SNCode,a.Status,a.Progress,b.MaterialCode,b.MaterialName,a.Remark
			,ROW_NUMBER()OVER(ORDER BY a.CreateDate DESC)RN
			,a.HardwareVersion,a.SoftwareVersion
			FROM dbo.TP_RDRcvDetail a INNER JOIN dbo.mxqh_Material b ON a.MaterialID=b.Id WHERE a.RcvID=@RcvID
			) t WHERE t.RN>@beginIndex AND t.RN<@endIndex

			SELECT (SELECT COUNT(1) FROM dbo.TP_RDRcvDetail a where a.RcvID=@RcvID)RcvCount
		END 
	END 
	ELSE--输入的是工单号
    BEGIN
		DECLARE @WorkOrderID INT
		IF EXISTS(SELECT 1 FROM dbo.mxqh_plAssemblyPlanDetail a WHERE a.WorkOrder=@SNCode)
		BEGIN
			SELECT @WorkOrderID=a.ID FROM dbo.mxqh_plAssemblyPlanDetail a WHERE a.WorkOrder=@SNCode
		END 
		ELSE
        BEGIN
			SELECT '0'MsgType,'['+@SNCode+']工单不存在！'Msg
			RETURN;
		END 

		IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#TempTable') AND TYPE='U')
		BEGIN
			DROP TABLE #TempTable
		END	

		--判断是是否是包装工单
		IF EXISTS(SELECT 1 FROM dbo.opPlanExecutMainPK WHERE AssemblyPlanDetailID=@WorkOrderID)
		BEGIN
			--判断是否有未完工SN编码（是否完工看组装数据）        
			
			SELECT t.InternalCode INTO #TempTable
			FROM
			(
			SELECT a.InternalCode,ROW_NUMBER()OVER(PARTITION BY a.InternalCode,a.ID ORDER BY c.OrderNum DESC,ISNULL(c.PassTime,FORMAT(GETDATE(),'yyyy-MM-dd HH:mm:ss')))RN,c.IsPass
			FROM dbo.opPlanExecutMainPK a INNER JOIN dbo.opPlanExecutDetailPK c ON a.ID=c.PlanExecutMainID
			WHERE a.AssemblyPlanDetailID=@WorkOrderID AND c.ExtendOne=0
			) t WHERE t.RN=1 AND t.IsPass=1
			--检查是否有入库记录
			IF EXISTS(SELECT 1 FROM #TempTable a INNER JOIN dbo.TP_RDRcvDetail b ON a.InternalCode=ISNULL(b.InternalCode,''))
			BEGIN
				SELECT '0'MsgType,(SELECT ISNULL(b.SNCode,b.InternalCode)+',' FROM #TempTable a INNER JOIN dbo.TP_RDRcvDetail b ON a.InternalCode=ISNULL(b.InternalCode,'')
				INNER JOIN dbo.TP_RDRcv c ON b.RcvID=c.ID FOR XML PATH(''))+'已经入库过，不能整单录入！'Msg
				RETURN;
			END 

			--插入数据
			INSERT INTO dbo.TP_RDRcvDetail
					( CreateBy ,
						  CreateDate ,
						  RcvID ,
						  InternalCode,
						  SNCode ,
						  MaterialID ,
						  MaterialCode ,
						  MaterialName ,
						  Status ,
						  Progress ,
						  Remark
					)
			SELECT @CreateBy,GETDATE(),@RcvID,b.InternalCode,b.SNCode,c.MaterialID,d.MaterialCode,d.MaterialName,@Status,@Progress,@Remark 
			FROM #TempTable a LEFT JOIN dbo.vw_baInternalAndSNCode b ON a.InternalCode=ISNULL(b.InternalCode,'')
			LEFT JOIN dbo.mxqh_plAssemblyPlanDetail c ON c.ID=@WorkOrderID LEFT JOIN dbo.mxqh_Material d ON c.MaterialID=d.Id
		
			SELECT '1'MsgType,'['+@SNCode+']整单扫码成功！'Msg
			--返回扫码集合
			SELECT * 		
			FROM (
			SELECT a.ID,a.InternalCode,a.SNCode,a.Status,a.Progress,b.MaterialCode,b.MaterialName,b.Spec,a.Remark,ROW_NUMBER()OVER(ORDER BY a.CreateDate DESC)RN
			FROM dbo.TP_RDRcvDetail a INNER JOIN dbo.mxqh_Material b ON a.MaterialID=b.Id WHERE a.RcvID=@RcvID
			) t WHERE t.RN>@beginIndex AND t.RN<@endIndex
			--入库数量
			SELECT (SELECT COUNT(1) FROM dbo.TP_RDRcvDetail a where a.RcvID=@RcvID)RcvCount
		END 
		ELSE
        BEGIN
			--判断是否有未完工SN编码（是否完工看组装数据）
        
			IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#TempTable2') AND TYPE='U')
			BEGIN
				DROP TABLE #TempTable2
			END		
			SELECT t.InternalCode INTO #TempTable2
			FROM
			(
			SELECT a.InternalCode,ROW_NUMBER()OVER(PARTITION BY a.InternalCode,a.ID ORDER BY c.OrderNum DESC,ISNULL(c.PassTime,FORMAT(GETDATE(),'yyyy-MM-dd HH:mm:ss')))RN,c.IsPass
			FROM dbo.opPlanExecutMain a INNER JOIN dbo.opPlanExecutDetail c ON a.ID=c.PlanExecutMainID
			WHERE a.AssemblyPlanDetailID=@WorkOrderID AND c.ExtendOne=0
			) t WHERE t.RN=1 AND t.IsPass=1
			--检查是否有入库记录
			IF EXISTS(SELECT 1 FROM #TempTable2 a INNER JOIN dbo.TP_RDRcvDetail b ON a.InternalCode=ISNULL(b.InternalCode,''))
			BEGIN
				SELECT '0'MsgType,(SELECT ISNULL(b.SNCode,'')+',' FROM #TempTable2 a INNER JOIN dbo.TP_RDRcvDetail b ON a.InternalCode=ISNULL(b.InternalCode,'')
				INNER JOIN dbo.TP_RDRcv c ON b.RcvID=c.ID FOR XML PATH(''))+'已经入库过，不能整单录入！'Msg
				RETURN;
			END 

			--插入数据
			INSERT INTO dbo.TP_RDRcvDetail
					( CreateBy ,
						  CreateDate ,
						  RcvID ,
						  InternalCode,
						  SNCode ,
						  MaterialID ,
						  MaterialCode ,
						  MaterialName ,
						  Status ,
						  Progress ,
						  Remark
					)
			SELECT @CreateBy,GETDATE(),@RcvID,a.InternalCode,b.SNCode,c.MaterialID,d.MaterialCode,d.MaterialName,@Status,@Progress,@Remark 
			FROM #TempTable2 a LEFT JOIN dbo.vw_baInternalAndSNCode b ON a.InternalCode=b.InternalCode
			LEFT JOIN dbo.mxqh_plAssemblyPlanDetail c ON c.ID=@WorkOrderID LEFT JOIN dbo.mxqh_Material d ON c.MaterialID=d.Id
		
			SELECT '1'MsgType,'['+@SNCode+']整单扫码成功！'Msg
			--返回扫码集合
			SELECT * 		
			FROM (
			SELECT a.ID,a.InternalCode,a.SNCode,a.Status,a.Progress,b.MaterialCode,b.MaterialName,b.Spec,a.Remark,ROW_NUMBER()OVER(ORDER BY a.CreateDate DESC)RN
			FROM dbo.TP_RDRcvDetail a INNER JOIN dbo.mxqh_Material b ON a.MaterialID=b.Id WHERE a.RcvID=@RcvID
			) t WHERE t.RN>@beginIndex AND t.RN<@endIndex
			--入库数量
			SELECT (SELECT COUNT(1) FROM dbo.TP_RDRcvDetail a where a.RcvID=@RcvID)RcvCount
		END 
		
	END 
	

END 


