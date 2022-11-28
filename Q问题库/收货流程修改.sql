SELECT code,DescFlexField_PrivateDescSeg1 FROM pm_rcvdoctype WHERE code='RCV30113'
SELECT id,a.DescFlexField_PrivateDescSeg1 
,a.DescFlexField_PrivateDescSeg2
,a.DescFlexField_PrivateDescSeg3
,a.DescFlexField_PrivateDescSeg4
,a.DescFlexField_PrivateDescSeg5
,a.DescFlexField_PrivateDescSeg6
FROM dbo.PM_Receivement a
WHERE a.DocNo='RCV30220102001'
--UPDATE dbo.PM_Receivement 
--SET DescFlexField_PrivateDescSeg3=''-- «∑Ò≤µªÿ
--,DescFlexField_PrivateDescSeg4=''-- «∑Ò∆˙…Û
--,DescFlexField_PrivateDescSeg5=''--OAFlowID
--WHERE DocNo='RCV30220102001'
