/* Audit query */
/* Position-level prefs that have prod URL links*/
select position=cv.display
     , a.application_number
     , a.description
     , tref.position_cd
     , nvp.name_value_prefs_id
     , nvp.pvc_name
     , nvp.pvc_value
     , nvp.sequence
from name_value_prefs nvp
, (INNER JOIN app_prefs tref
           ON tref.app_prefs_id = nvp.parent_entity_id
          AND tref.position_cd > 0       ;; Position-level pref
          AND tref.prsnl_id = 0 )        ;; Do not touch user-level prefs
, (INNER JOIN application a
           ON a.application_number = tref.application_number)
, (INNER JOIN code_value cv
           ON cv.code_value = tref.position_cd
          AND cv.code_set = 88
          AND cv.active_ind = 1)
WHERE cnvtupper(nvp.pvc_name) in ("APP_NAME*","WEBAPP_URL","INST_LINK_URL")
  and cnvtupper(nvp.pvc_value) in ("*P647*" , "*PROD*", "*PRD*")
  AND nvp.parent_entity_id > 0 
ORDER BY  a.description,a.application_number,cnvtupper(cv.display),nvp.sequence
go;

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
                       AND tref.position_cd > 0       ;; Position-level pref */
                       AND tref.prsnl_id = 0 )        ;; Do not touch user-level prefs
             , (INNER JOIN application a
                        ON a.application_number = tref.application_number)
             , (INNER JOIN code_value cv
                        ON cv.code_value = tref.position_cd
                       AND cv.code_set = 88
                       AND cv.active_ind = 1)
                     WHERE cnvtupper(nvp.pvc_name) in ("APP_NAME*","WEBAPP_URL","INST_LINK_URL")
                       AND cnvtupper(nvp.pvc_value) in ("*P647*" , "*PROD*", "*PRD*")
                       AND nvp.parent_entity_id > 0 )

