create or replace view v_auctus_kqmanagement as
with UserGroup as--人员考勤组
(
select a.id,a.groupname,b.type,b.typevalue,c.id userid,c.lastname from kq_group a inner join kq_groupmember b on a.id=b.groupid
inner join hrmresource c on b.type=1 and b.typevalue=c.id
where nvl(a.isdelete,0)!=1
and c.status in (0,1,2,3)
union all--分部
select a.id,a.groupname,b.type,b.typevalue,d.id userid,d.lastname
from kq_group a inner join kq_groupmember b on a.id=b.groupid
inner join hrmsubcompany c on b.type=2 and b.typevalue=c.id
left join hrmresource d on d.subcompanyid1=c.id
where nvl(a.isdelete,0)!=1
and nvl(b.isdelete,0)!=1
and d.status in (0,1,2,3)
union all--部门
select a.id,a.groupname,b.type,b.typevalue,d.id userid,d.lastname
from kq_group a inner join kq_groupmember b on a.id=b.groupid
inner join hrmdepartment c on b.type=3 and b.typevalue=c.id
left join hrmresource d on d.departmentid=c.id
where nvl(a.isdelete,0)!=1
and nvl(b.isdelete,0)!=1
and d.status in (0,1,2,3)
union all--岗位
select a.id,a.groupname,b.type,b.typevalue,d.id userid,d.lastname
from kq_group a inner join kq_groupmember b on a.id=b.groupid
inner join hrmjobtitles c on b.type=5 and b.typevalue=c.id
left join hrmresource d on d.jobtitle=c.id
where nvl(a.isdelete,0)!=1
and nvl(b.isdelete,0)!=1
and d.status in (0,1,2,3)
union all--所有人
select a.id,a.groupname,b.type,b.typevalue,d.id userid,d.lastname
from kq_group a , kq_groupmember b , hrmresource d 
where nvl(a.isdelete,0)!=1
and nvl(b.isdelete,0)!=1
and b.type=6
and d.status in (0,1,2,3)
)
select "GROUPNAME","USERID","LASTNAME","ID","WEEKDAY","SERIALID","GROUPID","ISDELETE","SERIAL","STARTTIME","ENDTIME","SERIOUSLATEMINUTES","RN" from (
--考勤组与上下班关系
select a.groupname,a.userid,a.lastname,b.*,c.serial,d.times starttime,d1.times EndTime
,e.seriouslateminutes
,row_number() over(partition by a.userid,b.weekday order by d.times)rn
from UserGroup a
left join kq_fixedschedulce b on a.id=b.groupid
left join kq_ShiftManagement c on b.serialid=c.id
left join KQ_SHIFTONOFFWORKSECTIONS d on c.id=d.serialid and d.onoffworktype='start'
left join KQ_SHIFTONOFFWORKSECTIONS d1 on c.id=d1.serialid and d1.onoffworktype='end'
left join kq_ShiftPersonalizedRule e on c.id=e.serialid
where 1=1
--and a.lastname='邓细芬'
--and a.groupname='卫生阿姨'
) t where t.rn=1;
