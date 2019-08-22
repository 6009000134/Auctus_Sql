
/*
标题：委外订单短缺关闭验证是否财务核销
开发时间：2018-7-12
需求部门：财务部
需求：委外订单短缺关闭时，若财务未核销（备料单行核销数量<>已发料数量），则不允许关闭
*/
ALTER PROC [dbo].[sp_Auctus_BE_PurchaseOrderAU]
(
@DocNo VARCHAR(50),
@Result NVARCHAR(MAX) OUT
)
AS
BEGIN

--DECLARE @Result2 NVARCHAR(MAX)
SET @Result=(
SELECT CONVERT(VARCHAR(10),d.PickLineNo)+','
---a.DocNo,b.DocLineNo,d.PickLineNo,d.IssuedQty,d.ActualReqQty,d.ApplyQty
FROM pm_purchaseorder a INNER JOIN pm_poline b ON a.ID=b.PurchaseOrder
INNER JOIN dbo.CBO_SCMPickHead c ON c.POLine=b.ID INNER JOIN dbo.CBO_SCMPickList d ON c.ID=d.PicKHead
WHERE a.DocNo=@DocNo
AND d.ApplyQty<>d.IssuedQty FOR XML PATH('')
)
IF ISNULL(@Result,'')=''
BEGIN
	SET @Result='1'
END 
ELSE
BEGIN
	SET @Result='备料行：'+LEFT(@Result,LEN(@Result)-1)+'未核销，不允许手工关闭'	
END 


END 