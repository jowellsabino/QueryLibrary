/* List orgs associated with a personel */
select pr.name_full_formatted
     , orgset_name=os.name
     , orgset_description=os.description
;     , org_name=org.org_name
;     , ORG_TYPE=cvorgtype.display
;     , org.*
;     , ospr.*
from prsnl pr
/* We link by org sets first, not orgs ??? */
, (inner join org_set_prsnl_r ospr
            on ospr.prsnl_id = pr.person_id
           and ospr.active_ind = 1
           and ospr.end_effective_dt_tm > sysdate)
, (inner join code_value cvorgtype
           on cvorgtype.code_value = ospr.org_set_type_cd
          and cvorgtype.active_ind = 1
          and cvorgtype.code_set = 28881)
, (inner join org_set os
           on os.org_set_id =  ospr.org_set_id
          and os.active_ind = 1
          and os.end_effective_dt_tm > sysdate) 
/* Link to orgs in an org set if needed to explicitly list orgs */
, (inner join org_set_org_r osor
           on osor.org_set_id = os.org_set_id
          and osor.active_ind = 1
          and osor.end_effective_dt_tm > sysdate)
, (inner join organization org
            on org.organization_id = osor.organization_id
           and org.active_ind = 1
           and org.end_effective_dt_tm > sysdate)

where pr.position_cd in (select code_value
                          from code_value
                         where code_set = 88
                           and active_ind = 1
                          and display_key = 'PHARMNETPHARMACIST*')
  and pr.active_ind = 1
  and pr.end_effective_dt_tm > sysdate
  and pr.username is not null
  and pr.person_id = 23247901
;  and ospr.prsnl_id = 8531805.00
;  and os.name = 'ALL ORGS'
  and  org.org_name = 'DFCI*'
order by pr.name_full_formatted,os.name,os.description;, org.org_name
go
