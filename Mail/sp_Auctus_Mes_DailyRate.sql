--/*
--备份每日mes排产达成率
--*/
ALTER  PROC [dbo].[sp_Auctus_Mes_DailyRate]
AS
BEGIN
SET NOCOUNT ON 
DECLARE @Date DATETIME =DATEADD(DAY,-1,GETDATE())
--DECLARE @Date datetime ='2020-09-19'
--DECLARE @Date DATETIME='2020-04-07 09:00:00'
--当天已经备份了数据，不再备份
IF NOT EXISTS(SELECT 1 FROM dbo.Auctus_MesDailyRate WHERE FORMAT(@Date,'yyyy-MM-dd')=PlanDate)
BEGIN
	IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#TempTable') AND TYPE='U')
	BEGIN
		;WITH PlanData AS
		(
		SELECT * FROM #TempTable
		),
		U9Data AS
		(
		SELECT b.DocNo,SUM(a.CompleteQty)CompleteQty
		FROM dbo.MO_CompleteRpt a INNER JOIN dbo.MO_MO b ON a.MO=b.ID
		WHERE a.CreatedOn>@Date
		AND a.CreatedOn<DATEADD(DAY,1,@Date)
		AND a.DocState=3
		GROUP BY b.DocNo
		),
		StartInfo AS
		(
		SELECT t.DocNo,ISNULL(SUM(t.StartQty),0)StartedQty
		FROM (
		SELECT b.DocNo,CASE WHEN a.BusinessDirection=0 THEN a.StartQty ELSE (-1)*a.StartQty END StartQty 
		FROM dbo.MO_MOStartInfo a INNER JOIN dbo.MO_MO b ON a.MO=b.ID
		INNER JOIN PlanData c ON b.DocNo=c.WorkOrder
		WHERE 
		--a.CreatedOn>@Date AND 
		a.CreatedOn<DATEADD(DAY,1,@Date)
		) t GROUP BY t.DocNo
		),
		MOPicks AS
		(
	SELECT * FROM (
		SELECT t.DocNo,MIN(t.MM)KittingCount,t.ItemFormAttribute
		FROM (
		SELECT a.DocNo,c.DocLineNO,CASE WHEN c.IssuedQty=0 THEN 0 ELSE  c.IssuedQty*a.ProductQty/CONVERT(DECIMAL(18,2),c.ActualReqQty)END MM
		,'KittingCount'+CONVERT(VARCHAR(10),m.ItemFormAttribute) ItemFormAttribute
		FROM MO_MO a INNER JOIN PlanData b  ON a.DocNo=b.WorkOrder INNER JOIN dbo.MO_MOPickList c ON a.ID=c.MO	
		LEFT JOIN dbo.CBO_ItemMaster m ON c.ItemMaster=m.ID
		WHERE c.IssueStyle=0 AND m.ItemFormAttribute IN (9,10)
		AND c.ActualReqQty>0
		) t GROUP BY t.DocNo,t.ItemFormAttribute) t1 PIVOT (MIN(t1.KittingCount) FOR ItemFormAttribute IN (KittingCount9,KittingCount10)) AS tt
		)
		INSERT INTO Auctus_MesDailyRate
		SELECT a.LineName,a.Name,FORMAT(a.PlanDate,'yyyy-MM-dd'),a.WorkOrder,a.MaterialCode,a.MaterialName,a.Spec,a.Quantity,a.PlanCount,a.TotalPlanCount
		,CONVERT(INT,ISNULL(u.CompleteQty,0))U9CompleteQty--U9完工数
		,CONVERT(INT,CASE WHEN a.PlanCount-ISNULL(u.CompleteQty,0)-ISNULL(a.NeedRepairNum,0)>=0 THEN a.PlanCount-ISNULL(u.CompleteQty,0)-ISNULL(a.NeedRepairNum,0) ELSE 0 END )
		UnCompleteQty--U9未完工数量
		,CONVERT(DECIMAL(18,2),(ISNULL(u.CompleteQty,0)+ISNULL(a.NeedRepairNum,0))/CONVERT(DECIMAL(18,2),a.PlanCount)*100) Rate--达成率
		,p.KittingCount9,p.KittingCount10
		,ISNULL(a.NeedRepairNum,0)NeedRepairNum--待维修数量
		,ISNULL(s.StartedQty,0) StartedQty--U9开工数量
		,GETDATE() CopyDate--备份日期
		,CASE WHEN m.DescFlexField_PrivateDescSeg18='' THEN 0.00 ELSE CONVERT(DECIMAL(18,4),m.DescFlexField_PrivateDescSeg18) END 
		,a.Rate DirectRate
		,a.StandPerson,a.ActPerson,a.Times
		,a.FinishSum
		FROM PlanData a 
		LEFT JOIN U9Data u ON a.WorkOrder=u.DocNo
		LEFT JOIN MOPicks p ON a.WorkOrder=p.DocNo
		LEFT JOIN StartInfo s ON a.WorkOrder=s.DocNo
		LEFT JOIN cbo_itemmaster m ON a.MaterialCode=m.code AND m.org=1001708020135665
	END 

	
END 
--备份3天数据
IF NOT EXISTS(SELECT 1 FROM auctus_mesdailyrate4u9 WHERE copydate=FORMAT(GETDATE(),'yyyy-MM-dd'))
BEGIN
INSERT INTO auctus_mesdailyrate4u9
SELECT DISTINCT
         CONCAT(d1.Name,
                    ISNULL(( SELECT v2.Name
                             FROM   Base_DefineValue v1
                                    INNER  JOIN Base_DefineValue_Trl v2 ON v1.ID = v2.ID
                             WHERE  ValueSetDef = 1001708040000182
                                    AND v1.Code = a1.DescFlexField_PrivateDescSeg6
                           ), ''))LineName ,
         a1.DocNo ,
         f.Code ,
         f.Name ,
         f.SPECS ,
         CONVERT(DECIMAL(18, 0), a1.ProductQty) ProductQty,
         CONVERT(DECIMAL(18, 0), a1.TotalStartQty)TotalStartQty ,
         ( SELECT   CONVERT(DECIMAL(18, 0), TotalRcvQty)
               FROM     MO_MO
               WHERE    DocNo = a1.DocNo
             ) TotalCompleteQty,
         CONVERT(DECIMAL(18, 0), a1.ProductQty)
        - ( SELECT  CONVERT(DECIMAL(18, 0), TotalRcvQty)
            FROM    MO_MO
            WHERE   DocNo = a1.DocNo
          )UnCompleteQty ,
         CONVERT(VARCHAR(11), MAX(a1.StartDate), 111) StartDate,
         ISNULL(CONVERT(VARCHAR(20), MIN(a2.StartDatetime), 111), '-') ActualStartDate,
         CONVERT(VARCHAR(11), a1.CompleteDate, 111) CompleteDate,
         ISNULL(DATEDIFF(DAY, a1.CompleteDate,
                             CONVERT(VARCHAR(100), GETDATE(), 111))
                    - CAST(3 AS INT), '-') DelayDays,
         ISNULL(CONVERT(VARCHAR(20), DATEADD(DAY,
                                                 DATEDIFF(DAY,
                                                          MIN(a1.StartDate),
                                                          CONVERT(VARCHAR(100), a1.CompleteDate, 111))
                                                 + CAST(3 AS INT),
                                                 MIN(a2.StartDatetime)), 111) ,
                    '-') SCompleteDate,
         ISNULL(( CASE WHEN CONVERT(VARCHAR(20), DATEDIFF(DAY,
                                                              DATEADD(DAY,
                                                              DATEDIFF(DAY,
                                                              MIN(a1.StartDate),
                                                              CONVERT(VARCHAR(100), a1.CompleteDate, 111))
                                                              + CAST(3 AS INT),
                                                              MIN(a2.StartDatetime)),
                                                              CONVERT(VARCHAR(100), GETDATE(), 111)), 111) < 0
                           THEN NULL
                           ELSE CONVERT(VARCHAR(20), DATEDIFF(DAY,
                                                              DATEADD(DAY,
                                                              DATEDIFF(DAY,
                                                              MIN(a1.StartDate),
                                                              CONVERT(VARCHAR(100), a1.CompleteDate, 111))
                                                              + CAST(3 AS INT),
                                                              MIN(a2.StartDatetime)),
                                                              CONVERT(VARCHAR(100), GETDATE(), 111)), 111)
                      END ), '-') DelayDate,FORMAT(GETDATE(),'yyyy-MM-dd')CopyDate
FROM    MO_MO a1
        LEFT JOIN CBO_Department_Trl d1 ON d1.ID = a1.Department
        LEFT JOIN MO_MOStartInfo a2 ON a1.ID = a2.MO
        LEFT JOIN dbo.CBO_ItemMaster f ON a1.ItemMaster = f.ID
WHERE   a1.Org = 1001708020135665
        AND a1.Cancel_Canceled != 1 --and  IsHoldRelease <> 1
        AND a1.MODocType != 1001803210037505
        AND DATEDIFF(DAY, a1.CompleteDate,
                     CONVERT(VARCHAR(100), GETDATE(), 111)) > 3
        AND a1.DocState NOT IN ( 3, 0 )
        --AND NOT EXISTS ( SELECT 1
        --                 FROM   MO_MO c
        --                 WHERE  a1.ID = c.ID AND c.BusinessType = 48 )
GROUP BY d1.Name ,
        a1.DescFlexField_PrivateDescSeg6 ,
        a1.DocNo ,
        a1.TotalStartQty ,
        a1.StartDate ,
        a1.CompleteDate ,
        a1.ProductQty ,
        f.Name ,
        f.Code ,
        f.SPECS;
END 
;

SET NOCOUNT OFF

WHILE NOT EXISTS(SELECT 1 FROM dbo.Auctus_MesDailyRate WHERE PlanDate=FORMAT(@Date,'yyyy-MM-dd'))
BEGIN
	IF @Date<'2020-09-01'
	BEGIN
		BREAK;
	END 
	SET @Date=DATEADD(DAY,-1,@Date)
	IF EXISTS(SELECT 1 FROM dbo.Auctus_MesDailyRate WHERE PlanDate=FORMAT(@Date,'yyyy-MM-dd'))
	BEGIN
		BREAK;
	END 
END	

--SELECT  TOP 1 1 MailNo, 'gaolq@auctus.cn,gexj@auctus.cn,zougl@auctus.cn,liaocw@auctus.com,stephy@auctus.cn,perla_yu@auctus.cn,winnie@auctus.cn,huangxh@auctus.cn,linyf@auctus.cn,hanlm@auctus.cn,andy@auctus.cn,wangjm@auctus.com,yangm@auctus.cn,buyerpm01@auctus.cn,buyermd01@auctus.cn,yanjing@auctus.com,xupp@auctus.com,mall@auctus.com,ningzh@auctus.cn,caixt@auctus.cn,lixb@auctus.cn,xubin@auctus.com,wusq@auctus.com,tonghui@auctus.cn,lihb@auctus.cn,liuyy@auctus.cn,liufei@auctus.com,line07@auctus.com,line01@auctus.com,line02@auctus.com,line5a@auctus.com,line5b@auctus.com,line6a@auctus.com,line3b@auctus.com' AS MailTo, 'DailyRate.xml' AS  XmlName, '刘飞' CHI_NAME, 'dddsfal' FORM_TYPE		
--SELECT  TOP 1 1 MailNo, 'liufei@auctus.com' AS MailTo, 'DailyRate.xml' AS  XmlName, '刘飞' CHI_NAME, 'dddsfal' FORM_TYPE		
SELECT  TOP 1 1 MailNo, 'BDPRecipients@auctus.cn,zuzhang@auctus.cn,guzh@auctus.cn,daicq@auctus.cn,meijh@auctus.com,caiqm@auctus.com,chenyq@auctus.com' AS MailTo, 'DailyRate.xml' AS  XmlName, '刘飞' CHI_NAME, 'dddsfal' FORM_TYPE		
--SELECT  TOP 1 1 MailNo, 'gaolq@auctus.cn' AS MailTo, 'DailyRate.xml' AS  XmlName, '刘飞' CHI_NAME, 'dddsfal' FORM_TYPE		
,FORMAT(@Date,'yyyy-MM-dd')NowDate,DATENAME(WEEKDAY,@Date)WD

--SELECT 1 MailNo
--,a.LineName,a.Name,a.PlanDate,a.WorkOrder,a.MaterialCode,a.MaterialName,a.Quantity,a.PlanCount
--,a.TotalPlanCount,a.U9CompleteQty,ISNULL(a.NeedRepairNum,0)NeedRepairNum,a.UnCompleteQty,a.Rate
--,CASE WHEN ISNULL(a.KittingCount9,0)=0 THEN '齐套'
--WHEN a.KittingCount9-CASE WHEN a.TotalPlanCount>a.Quantity THEN a.Quantity ELSE a.TotalPlanCount END>=0 THEN '齐套'
--ELSE '不齐套' END IsKitting9
--,CASE WHEN ISNULL(a.KittingCount9,0)=0 THEN ''
--WHEN KittingCount9-CASE WHEN a.TotalPlanCount>a.Quantity THEN a.Quantity ELSE a.TotalPlanCount END>=0 THEN ''
--ELSE 'background:red;' END IsKittingStyle9
--,CASE WHEN ISNULL(a.KittingCount10,0)=0 THEN '齐套'
--WHEN a.KittingCount10-CASE WHEN a.TotalPlanCount>a.Quantity THEN a.Quantity ELSE a.TotalPlanCount END>=0 THEN '齐套'
--ELSE '不齐套' END IsKitting10
--,CASE WHEN ISNULL(a.KittingCount10,0)=0 THEN ''
--WHEN KittingCount10-CASE WHEN a.TotalPlanCount>a.Quantity THEN a.Quantity ELSE a.TotalPlanCount END>=0 THEN ''
--ELSE 'background:red;' END IsKittingStyle10
--,ROW_NUMBER()OVER(ORDER BY a.LineName)RN
--,a.Upph*a.ActPerson*a.PlanTime StandOutput--标准产量
--,a.StandPerson,a.ActPerson,a.PlanTime,a.DirectRate
--,a.Upph,a.MesCompleteQty
--,CASE WHEN a.Upph=0 OR a.ActPerson=0 OR a.PlanTime=0 THEN  a.U9CompleteQty/a.Upph*a.ActPerson*a.PlanTime END UpphRate
--FROM Auctus_MesDailyRate a WHERE a.PlanDate=FORMAT(@Date,'yyyy-MM-dd')

;
WITH data1 AS
(
SELECT a.LineName,a.Name,a.PlanDate,a.WorkOrder,a.MaterialCode,a.MaterialName,a.Quantity,a.PlanCount
,a.TotalPlanCount,a.U9CompleteQty,ISNULL(a.NeedRepairNum,0)NeedRepairNum,a.UnCompleteQty,a.Rate
,CASE WHEN ISNULL(a.KittingCount9,0)=0 THEN '齐套'
WHEN a.KittingCount9-CASE WHEN a.TotalPlanCount>a.Quantity THEN a.Quantity ELSE a.TotalPlanCount END>=0 THEN '齐套'
ELSE '不齐套' END IsKitting9
,CASE WHEN ISNULL(a.KittingCount9,0)=0 THEN ''
WHEN KittingCount9-CASE WHEN a.TotalPlanCount>a.Quantity THEN a.Quantity ELSE a.TotalPlanCount END>=0 THEN ''
ELSE 'background:red;' END IsKittingStyle9
,CASE WHEN ISNULL(a.KittingCount10,0)=0 THEN '齐套'
WHEN a.KittingCount10-CASE WHEN a.TotalPlanCount>a.Quantity THEN a.Quantity ELSE a.TotalPlanCount END>=0 THEN '齐套'
ELSE '不齐套' END IsKitting10
,CASE WHEN ISNULL(a.KittingCount10,0)=0 THEN ''
WHEN KittingCount10-CASE WHEN a.TotalPlanCount>a.Quantity THEN a.Quantity ELSE a.TotalPlanCount END>=0 THEN ''
ELSE 'background:red;' END IsKittingStyle10
,CONVERT(INT,ISNULL(a.Upph ,0)*(CASE WHEN ISNULL(a.ActPerson,0)=0 THEN ISNULL(a.StandPerson,0) ELSE a.ActPerson END ) *a.PlanTime) StandOutput--标准产量
,ISNULL(a.StandPerson,0)StandPerson,ISNULL(a.ActPerson,0)ActPerson,CONVERT(DECIMAL(18,2),a.PlanTime)PlanTime,CONVERT(DECIMAL(18,2),ISNULL(a.DirectRate,0))DirectRate
,CONVERT(DECIMAL(18,2),a.Upph)Upph,a.MesCompleteQty
,CONVERT(VARCHAR(10),CONVERT(DECIMAL(18,2),CASE WHEN a.Upph=0 OR (a.ActPerson=0 AND a.StandPerson=0)OR a.PlanTime=0 THEN 0 ELSE  a.U9CompleteQty/(a.Upph*CASE WHEN ISNULL(a.ActPerson,0)=0 THEN a.StandPerson ELSE a.ActPerson end*a.PlanTime) END*100)) UpphRate
,ROW_NUMBER() OVER(PARTITION BY a.LineName ORDER BY a.Name,a.WorkOrder)RN
,ROW_NUMBER() OVER(PARTITION BY a.LineName,a.Name ORDER BY a.Name,a.WorkOrder)RN2
FROM Auctus_MesDailyRate a WHERE a.PlanDate=CONVERT(DATE,@Date)
),
Result AS
(
SELECT * FROM data1 
UNION ALL 
SELECT a.LineName,'汇总'Name,MIN(a.PlanDate)PlanDate,''WorkOrder,''MaterialCode,''MaterialName
,SUM(a.Quantity)Quantity,SUM(a.PlanCount)PlanCount,SUM(a.TotalPlanCount)TotalPlanCount,SUM(a.U9CompleteQty)U9COmpleteQty
,SUM(a.NeedRepairNum)NeedRepairNum,SUM(a.UnCompleteQty)UnCompleteQty
,CONVERT(DECIMAL(18,2),(SUM(a.U9CompleteQty)+SUM(a.NeedRepairNum))/CONVERT(DECIMAL(18,2),SUM(a.PlanCount))*100)Rate
,''IsKitting9,''IsKittingStyle9,''IsKitting10,''IsKittingStyle10
,SUM(ISNULL(a.StandOutput,0))StandOutput,SUM(ISNULL(a.StandPerson,0))StandPerson,SUM(ISNULL(a.ActPerson,0))ActPerson
,SUM(a.PlanTime)PlanTime
,CONVERT(DECIMAL(18,2),ISNULL(SUM(a.PlanCount*a.DirectRate)/SUM(a.PlanCount),0))DirectRate
,SUM(a.Upph)Upph
,SUM(a.MesCompleteQty)MesCompleteQty
,CONVERT(VARCHAR(10),CONVERT(DECIMAL(18,2),CASE WHEN SUM(ISNULL(a.StandOutput,0))=0 THEN 0 ELSE SUM(a.U9CompleteQty)/CONVERT(DECIMAL(18,4),SUM(ISNULL(a.StandOutput,0)))END*100))UpphRate
,MAX(a.RN)+1 RN
,MAX(a.RN2)+1 RN2
FROM data1 a 
GROUP BY a.LineName
)
SELECT 
1 MailNo,(SELECT COUNT(1) FROM Result t WHERE t.LineName=a.LineName)RowSpan
,(SELECT COUNT(1) FROM Result t WHERE t.LineName=a.LineName AND t.Name=a.Name)RowSpan2
,DENSE_RANK()OVER(ORDER BY a.LineName)OrderNo
,CASE WHEN a.RN=1 THEN '' ELSE 'display:none;' END Style
,CASE WHEN a.RN2=1 OR a.Name='汇总' THEN '' ELSE 'display:none;' END Style2
,CASE WHEN a.Name='汇总' THEN 'background-color:#C5C5CC;' ELSE 'background-color:transparent;' END StyleBg
,a.LineName,a.Name,a.PlanDate,a.WorkOrder,a.MaterialCode,a.MaterialName,a.Quantity,a.PlanCount,a.TotalPlanCount,a.U9CompleteQty
,a.NeedRepairNum,a.UnCompleteQty,a.Rate,a.IsKitting9,a.IsKittingStyle9,a.IsKitting10,a.IsKittingStyle10,a.StandOutput,CASE WHEN a.Name='汇总' THEN '/' ELSE CONVERT(VARCHAR(10),a.StandPerson) END StandPerson
,CASE WHEN a.Name='汇总' THEN '/' ELSE CONVERT(VARCHAR(10),a.ActPerson) END ActPerson
,a.PlanTime,CONVERT(VARCHAR(20),a.DirectRate*100)+'%'DirectRate
,CASE WHEN a.Name='汇总' THEN '/' ELSE CONVERT(VARCHAR(20),a.Upph) END Upph
,a.MesCompleteQty,CONVERT(VARCHAR(20),a.UpphRate)+'%'UpphRate,a.RN,a.RN2
FROM Result a
ORDER BY a.LineName,a.RN

--SELECT 
--1 MailNo,(SELECT COUNT(1) FROM Result t WHERE t.LineName=a.LineName)RowSpan
--,(SELECT COUNT(1) FROM Result t WHERE t.LineName=a.LineName AND t.Name=a.Name)RowSpan2
--,DENSE_RANK()OVER(ORDER BY a.LineName)OrderNo
--,CASE WHEN a.RN=1 THEN 'display:block;' ELSE 'display:none;' END Style
--,CASE WHEN a.RN2=1 OR a.Name='汇总' THEN 'display:block;' ELSE 'display:none;' END Style2
--,CASE WHEN a.Name='汇总' THEN 'background-color:gray;' ELSE 'background-color:transparent;' END StyleBg
--,a.* 
--FROM Result a
--ORDER BY a.LineName,a.RN

		
--SELECT    1 MailNo,ROW_NUMBER() OVER ( ORDER BY DocNo DESC ) RN,* FROM dbo.Auctus_MesDailyRate4u9  WHERE CopyDate=FORMAT(GETDATE(),'yyyy-MM-dd')

DECLARE @Date2 DATE=GETDATE()
;
WITH TodayData AS
(
SELECT *FROM dbo.Auctus_MesDailyRate4U9 a WHERE CONVERT(DATE,a.CopyDate)=@Date2
),
YesterdayData AS
(
SELECT * FROM dbo.Auctus_MesDailyRate4U9 a WHERE CONVERT(DATE,a.CopyDate)=DATEADD(DAY,-1,@Date2)
)
SELECT 
1 MailNo,ROW_NUMBER() OVER ( ORDER BY ISNULL(a.DocNo,b.DocNo) DESC ) RN,
ISNULL(a.LineName,b.LineName)LineName,
ISNULL(a.DocNo,b.DocNo)DocNo,
ISNULL(a.Code,b.Code)Code,
ISNULL(a.Name,b.Name)Name,
ISNULL(a.SPECS,b.SPECS)SPECS,
ISNULL(a.ProductQty,b.ProductQty)ProductQty,
ISNULL(a.TotalStartQty,b.TotalStartQty)TotalStartQty,
ISNULL(a.TotalCompleteQty,b.TotalCompleteQty)TotalCompleteQty,
ISNULL(a.UnCompleteQty,b.UnCompleteQty)UnCompleteQty,
ISNULL(a.StartDate,b.StartDate)StartDate,
ISNULL(a.ActualStartDate,b.ActualStartDate)ActualStartDate,
ISNULL(a.CompleteDate,b.CompleteDate)CompleteDate,
ISNULL(a.DelayDays,b.DelayDays)DelayDays,
ISNULL(a.SCompleteDate,b.SCompleteDate)SCompleteDate,
ISNULL(a.DelayDate,b.DelayDate)DelayDate,
CASE WHEN ISNULL(a.DocNo,'')='' AND ISNULL(b.DocNo,'')!='' AND EXISTS(SELECT 1 FROM dbo.MO_MO t WHERE t.DocState=3 AND t.DocNo=b.docno) THEN 'background-color:green;'
WHEN ISNULL(a.DocNo,'')='' AND ISNULL(b.DocNo,'')!='' AND EXISTS(SELECT 1 FROM dbo.MO_MO t WHERE t.DocState!=3 AND t.DocNo=b.docno) THEN 'background-color:yellow;'
WHEN ISNULL(a.DocNo,'')!='' AND ISNULL(b.DocNo,'')!='' THEN ''
WHEN ISNULL(a.DocNo,'')!='' AND ISNULL(b.DocNo,'')='' THEN 'background-color:#19a9d5;'
ELSE '' END CompareStyle,
CASE WHEN ISNULL(a.DocNo,'')='' AND ISNULL(b.DocNo,'')!='' AND EXISTS(SELECT 1 FROM dbo.MO_MO t WHERE t.DocState=3 AND t.DocNo=b.docno) THEN '已完工'
WHEN ISNULL(a.DocNo,'')='' AND ISNULL(b.DocNo,'')!='' AND EXISTS(SELECT 1 FROM dbo.MO_MO t WHERE t.DocState!=3 AND t.DocNo=b.docno) THEN '修改了计划开工时间'
WHEN ISNULL(a.DocNo,'')!='' AND ISNULL(b.DocNo,'')!='' THEN ''
WHEN ISNULL(a.DocNo,'')!='' AND ISNULL(b.DocNo,'')='' THEN '新增未完工单'
ELSE '' END Remark
FROM TodayData a FULL JOIN YesterdayData b ON a.DocNo=b.DocNo
ORDER BY RN
END 





