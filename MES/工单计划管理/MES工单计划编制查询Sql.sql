--MES�����ƻ����Ʋ�ѯSql
SELECT  a.* ,
        b.AssemblyDate ,
        b.AssemblyLineName ,
        ( SELECT    COUNT(1)
          FROM      opPlanExecutMain
          WHERE     AssemblyPlanDetailID = a.ID
        ) AS OnlineQty ,--Ͷ������
        ( SELECT    COUNT(1)
          FROM      dbo.opPackageChild AS a1
                    INNER JOIN opPackageDetail AS b1 ON a1.PackDetailID = b1.ID
                    INNER JOIN opPackageMain AS c1 ON b1.PackMainID = c1.ID
          WHERE     c1.AssemblyPlanDetailID = a.ID
        ) AS FinishQty--�깤����
FROM    plAssemblyPlanDetail AS a
        INNER JOIN plAssemblyPlan AS b ON a.AssemblyPlanID = b.ID
WHERE   a.ExtendOne IS NULL
        --AND b.AssemblyLineID = 2
ORDER BY WorOrder DESC;

SELECT a.ID,COUNT(a.ID) FROM  dbo.plAssemblyPlanDetail a INNER JOIN dbo.opPackageMain b ON a.ID=b.AssemblyPlanDetailID INNER JOIN dbo.opPackageDetail c ON b.ID=c.PackMainID
INNER JOIN dbo.opPackageChild d ON c.ID=d.PackDetailID
GROUP BY a.ID

SELECT a.ID,COUNT(a.ID) FROM dbo.plAssemblyPlanDetail a INNER JOIN dbo.opPlanExecutMain b ON a.ID=b.AssemblyPlanDetailID
GROUP BY a.ID


SELECT COUNT(*) FROM opPlanExecutMain


SELECT TOP 100 * FROM opPackageChild--��װ�ӱ�

SELECT * FROM opPackageMain--��װ����

SELECT * FROM opPackageDetail--��װ��ϸ��

SELECT COUNT(*) FROM opPackageChild
SELECT COUNT(*) FROM opPackageMain
SELECT COUNT(*) FROM opPackageDetail
