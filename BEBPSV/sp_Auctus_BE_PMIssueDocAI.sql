
/*
非成套领料单BE

领料来源单据PO行是非审核状态时，提示：委外订单XXX非核状态不允许发料，请检查！
*/
CREATE   PROC [dbo].[sp_Auctus_BE_PMIssueDocAI]
(
@DocNo VARCHAR(50),
@Result VARCHAR(MAX) OUT--1为正常、否则提示有问题的行
)
AS
BEGIN 
	IF EXISTS(SELECT 1	FROM dbo.PM_IssueDoc a INNER JOIN dbo.PM_IssueDocLine b ON a.ID=b.PMIssueDoc
	INNER JOIN dbo.CBO_ItemMaster c ON b.Item=c.ID	INNER JOIN pm_poline poLine ON b.POLine=poLine.ID
	WHERE  a.Org=(SELECT id FROM dbo.Base_Organization WHERE Code='300')
	AND a.IssueDirection=0
	--AND a.DocNo='PMI30191104007'
	AND a.DocNo=@DocNo
	AND poLine.Status<>2
	)
	BEGIN
			
		SET @Result='委外订单'+(SELECT DISTINCT po.DocNo+','	FROM dbo.PM_IssueDoc a INNER JOIN dbo.PM_IssueDocLine b ON a.ID=b.PMIssueDoc
			INNER JOIN dbo.CBO_ItemMaster c ON b.Item=c.ID	INNER JOIN pm_poline poLine ON b.POLine=poLine.ID INNER JOIN dbo.PM_PurchaseOrder po ON po.ID=poLine.PurchaseOrder
			WHERE  a.Org=(SELECT id FROM dbo.Base_Organization WHERE Code='300')
			AND a.IssueDirection=0			
			AND a.DocNo=@DocNo
			AND poLine.Status<>2
			FOR XML PATH(''))+'非审核状态不允许发料，请检查！'
	END 
	ELSE
    BEGIN
		SET @Result='1'
	END 
END 