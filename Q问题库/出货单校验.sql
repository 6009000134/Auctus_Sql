

DECLARE @DocNo VARCHAR(50)='SM30202101005',@Data VARCHAR(MAX)='1002101220000543|60,1002101220000552|7,1002101220000561|2,1002101220000525|9101,1002101220000534|700'
DECLARE @Result VARCHAR(MAX)
IF object_id(N'tempdb.dbo.#tempShip',N'U') is NULL
BEGIN 
CREATE TABLE #tempShip
(
ID BIGINT,
Num INT
)
END
ELSE 
BEGIN
TRUNCATE TABLE #tempShip
END
INSERT INTO #tempShip
        ( ID, Num )
SELECT SUBSTRING(strID,0,PATINDEX('%|%',strID)) LineID,SUBSTRING(strID,PATINDEX('%|%',strID)+1,LEN(strID)) Qty
FROM dbo.fun_Cust_StrToTable(@Data)




IF	EXISTS(
SELECT 1
FROM dbo.SM_Ship a
INNER JOIN dbo.SM_ShipLine b ON a.ID=b.Ship
WHERE a.DocNo=@DocNo
AND b.SrcDocNo!=''
)
BEGIN
	;
	WITH ShipData AS--��������Ϣ
	(
	SELECT a.DocNo,b.ID LineID,b.DocLineNo,b.ItemInfo_ItemID,b.ItemInfo_ItemCode,b.SrcDocNo,b.SrcDocLineNo,b.SrcDocSubLineNo,b.QtyPriceAmount 
	,b.LotInfo_LotMaster LotID
	FROM dbo.SM_Ship a
	INNER JOIN dbo.SM_ShipLine b ON a.ID=b.Ship
	WHERE a.DocNo=@DocNo
	AND b.SrcDocNo!=''
	--GROUP BY b.SrcDocNo,b.SrcDocLineNo,b.SrcDocSubLineNo
	),
	ShipData2 AS--�ѳ�������
	(
	SELECT b.SrcDocNo,b.SrcDocLineNo,b.SrcDocSubLineNo,b.ItemInfo_ItemID,SUM(b.QtyPriceAmount)Qty FROM dbo.SM_Ship a INNER JOIN dbo.SM_ShipLine b ON a.ID=b.Ship
	INNER JOIN ShipData d ON b.SrcDocNo=d.SrcDocNo AND b.SrcDocLineNo=d.SrcDocLineNo AND b.SrcDocSubLineNo=d.SrcDocSubLineNo
	WHERE a.DocNo!=@DocNo
	AND a.Status=3--�Ѻ�׼
	AND b.SrcDocNo!=''
	GROUP BY b.SrcDocNo,b.SrcDocLineNo,b.SrcDocSubLineNo,b.ItemInfo_ItemID
	),
	SOData AS
	(
	SELECT a.ID,a.DocNo,b.DocLineNo,c.DocSubLineNo,c.ShipPlanQtyPU,ISNULL(c.ShipPlanQtyTU-ISNULL(t2.Qty,0),0)CanShipQty
	,c.ItemInfo_ItemID
	FROM dbo.SM_SO a
	INNER JOIN dbo.SM_SOLine b ON a.ID=b.SO
	INNER JOIN dbo.SM_SOShipline c ON b.ID=c.SOLine
	INNER JOIN (SELECT t.SrcDocNo,t.SrcDocLineNo,t.SrcDocSubLineNo FROM ShipData t GROUP BY t.SrcDocNo,t.SrcDocLineNo,t.SrcDocSubLineNo) t1 ON a.DocNo=t1.SrcDocNo AND b.DocLineNo=t1.SrcDocLineNo AND c.DocSubLineNo=t1.SrcDocSubLineNo
	LEFT JOIN ShipData2 t2 ON  a.DocNo=t2.SrcDocNo AND b.DocLineNo=t2.SrcDocLineNo AND c.DocSubLineNo=t2.SrcDocSubLineNo AND c.ItemInfo_ItemID=t2.ItemInfo_ItemID
	)
	SELECT t.*,b.DocNo,b.DocLineNo,b.DocSubLineNo,b.CanShipQty INTO #temptable  FROM (
	SELECT a.SrcDocNo,a.SrcDocLineNo,a.SrcDocSubLineNo,a.ItemInfo_ItemID,a.ItemInfo_ItemCode,SUM(b.Num)Num
	FROM ShipData a INNER JOIN #tempShip b ON a.LineID=b.ID
	GROUP BY a.SrcDocNo,a.SrcDocLineNo,a.SrcDocSubLineNo,a.ItemInfo_ItemID,a.ItemInfo_ItemCode
	) t LEFT JOIN SOData b ON t.SrcDocNo=b.DocNo AND t.SrcDocLineNo=b.DocLineNo AND t.SrcDocSubLineNo=b.DocSubLineNo AND t.ItemInfo_ItemID=b.ItemInfo_ItemID
	IF EXISTS(SELECT 1 FROM #temptable)
	BEGIN
		SET @Result=(SELECT a.ItemInfo_ItemCode+'������'+CONVERT(VARCHAR(20),a.Num)+'�������۶���'+a.DocNo+'-'+convert(VARCHAR(20),a.DocLineNo)+'-'+CONVERT(VARCHAR(20),a.DocSubLineNo)+'δ������'+CONVERT(VARCHAR(20),a.CanShipQty)+';' FROM #temptable a FOR XML PATH(''))
	END 
	ELSE
    BEGIN
		SET @Result='1'
	END 
END 
ELSE
BEGIN--�ֹ�������У��SO�ɳ�����
	SET @Result='1'
END 


--У�����Ƿ���
;
WITH ShipData AS
(
	SELECT a.DocNo,b.ID,b.WH,b.ItemInfo_ItemID,b.QtyPriceAmount,a.Status,ISNULL(b.LotInfo_LotMaster,0) LotID
	FROM dbo.SM_Ship a
	INNER JOIN dbo.SM_ShipLine b ON a.ID=b.Ship
	--WHERE a.DocNo=@DocNo
	WHERE a.Status!=3
),
NowData AS
(
SELECT * FROM ShipData a WHERE a.DocNo=@DocNo
),
UnApproveData AS
(
SELECT a.ItemInfo_ItemID,a.LotID,a.WH,SUM(a.QtyPriceAmount)TotalQty FROM ShipData a 
WHERE a.DocNo!=@DocNo
AND a.ItemInfo_ItemID IN (
SELECT DISTINCT iteminfo_itemid FROM NowData
)
GROUP BY a.ItemInfo_ItemID,a.LotID,a.WH
),
Result AS
(
--SELECT * FROM #tempShip a INNER JOIN NowData b ON a.ID=b.ID 
--LEFT JOIN UnApproveData c ON b.ItemInfo_ItemID=c.ItemInfo_ItemID
SELECT b.ItemInfo_ItemID,b.LotID,SUM(a.Num)Num,SUM(b.QtyPriceAmount)Qty,MAX(ISNULL(c.TotalQty,0))TotalQty 
,MAX(d.TotalStoreQty)TotalStoreQty
FROM #tempShip a INNER JOIN NowData b ON a.ID=b.ID 
LEFT JOIN UnApproveData c ON b.ItemInfo_ItemID=c.ItemInfo_ItemID
LEFT JOIN dbo.v_cust_ShipWh d ON b.ItemInfo_ItemID=d.ItemID AND b.LotID=d.LotID AND d.WhID=b.WH
GROUP BY b.ItemInfo_ItemID,b.LotID,b.WH
)
--SELECT *
--FROM Result a 
--INNER JOIN dbo.CBO_ItemMaster b ON a.ItemInfo_ItemID=b.ID
SELECT @Result=(
SELECT b.Code+'����������'+CONVERT(VARCHAR(20),a.Num)+'���ڹ�Ӧ������'+CONVERT(VARCHAR(20),CONVERT(INT,a.TotalStoreQty))+'-'+CONVERT(VARCHAR(20),CONVERT(INT,a.TotalQty))+'='+CONVERT(VARCHAR(20),CONVERT(INT,ISNULL(a.TotalStoreQty,0)-ISNULL(a.TotalQty,0)))+';'
FROM Result a 
INNER JOIN dbo.CBO_ItemMaster b ON a.ItemInfo_ItemID=b.ID
WHERE a.TotalStoreQty-a.TotalQty-a.Num<0
FOR XML PATH('')
)
IF @Result='' OR ISNULL(@Result,'1')='1'
SET @Result='1'

SELECT @Result
