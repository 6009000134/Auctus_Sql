
SELECT  DISTINCT code from MRP_ExceedItemLLC
ORDER BY Code
--SELECT  *
--FROM    dbo.CBO_BOMComponent a
--WHERE   a.ItemMaster = ( SELECT ID
--                         FROM   dbo.CBO_ItemMaster
--                         WHERE  Code = '204010559'
--                                AND Org = ( SELECT  ID
--                                            FROM    dbo.Base_Organization
--                                            WHERE   Code = '300'
--                                          )
										  
--                       )AND a.DisableDate>GETDATE()

					   SELECT b.ID,a.BOMMaster,a.Sequence,a.ItemMaster,b.ItemMaster,b.Sequence,a.SubSeq,b.SubSeq ,c.Code,d.Code
					   ,ma.BOMVersionCode,e.Code
					   FROM dbo.CBO_BOMComponent a INNER JOIN 
					   (SELECT  *
FROM    dbo.CBO_BOMComponent a
WHERE   a.ItemMaster = ( SELECT ID
                         FROM   dbo.CBO_ItemMaster
                         WHERE  Code = '204010559'
                                AND Org = ( SELECT  ID
                                            FROM    dbo.Base_Organization
                                            WHERE   Code = '300'
                                          )
										  --333170086
										  
                       )
					   --AND a.DisableDate>GETDATE()
					   ) b ON a.BOMMaster=b.BOMMaster AND a.Sequence=b.Sequence  --AND b.DisableDate>GETDATE()
					   INNER JOIN dbo.CBO_ItemMaster c ON a.ItemMaster=c.ID INNER JOIN dbo.CBO_ItemMaster d ON b.ItemMaster=d.ID
					   INNER JOIN dbo.CBO_BOMMaster ma ON a.BOMMaster=ma.id INNER JOIN dbo.CBO_ItemMaster e ON ma.itemmaster=e.id
					   WHERE a.subseq!=0
					   ORDER BY a.BOMMaster

		--101010454 ÷ÿ∏¥¡œ∫≈		
		


			   