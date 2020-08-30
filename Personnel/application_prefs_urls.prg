/* Audit query */
/* Application-level, global prefs that have prod URL links */
select a.application_number
     , a.description
     , nvp.name_value_prefs_id
     , nvp.pvc_name
     , nvp.pvc_value
     , nvp.sequence
from name_value_prefs nvp
, (INNER JOIN app_prefs tref        
           ON tref.app_prefs_id = nvp.parent_entity_id
          AND tref.position_cd = 0  ;; Set these two conditions to get 
          AND tref.prsnl_id = 0     ;; appplication-level, global defaults 
          AND tref.application_number > 0)
, (INNER JOIN application a
           ON a.application_number = tref.application_number)
WHERE cnvtupper(nvp.pvc_name) in ('*APP_NAME*'); ("APP_NAME*","WEBAPP_URL","INST_LINK_URL")
  and cnvtupper(nvp.pvc_value) in ("*P647*" , "*PROD*", "*PRD*")
  AND nvp.parent_entity_id > 0
ORDER BY  a.description,a.application_number, tref.prsnl_id,nvp.sequence
go

/* Update prefs */
/* The replace function is CASE-SENSITIVE, EXACT MATCHING, and replaes ALL occurrences of the sting */
update into name_value_prefs 
set pvc_value = replace(pvc_value,'prod','test') /* arguments: string to process, search string, replace strng */
  , updt_dt_tm = sysdate
  , updt_id = 8531805.00  ;; *** REPLACE WITH YOUR PERSON_ID ***
  , updt_cnt = updt_cnt+1
where name_value_prefs_id in (
         select nvp.name_value_prefs_id
           from name_value_prefs nvp
             , (INNER JOIN app_prefs tref
                        ON tref.app_prefs_id = nvp.parent_entity_id
                       AND tref.position_cd = 0  ;; Set these two conditions to get 
                       AND tref.prsnl_id = 0     ;; appplication-level, global defaults 
                       AND tref.application_number > 0)
             , (INNER JOIN application a
                        ON a.application_number = tref.application_number)
                WHERE cnvtupper(nvp.pvc_name) in ('*APP_NAME*'); ("APP_NAME*","WEBAPP_URL","INST_LINK_URL")
                  AND cnvtupper(nvp.pvc_value) in ("*P647*" , "*PROD*", "*PRD*")
                  AND nvp.parent_entity_id > 0)
