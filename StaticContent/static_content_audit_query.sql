/* Query all prefs that mention "static_content */
/* We also want to capture new-gen mpages that query dm_info */
select cv.display AS position
     , a.description AS APPLICATION
     , vpref.frame_type AS PREF_LEVEL
     , dpref.view_name AS TAB_NAME
     , nvpq.pvc_value AS TAB_DISPLAY_SEQ
     , nvpr.pvc_value AS COMPONENT_CAPTION_NAME
     , nvpc.pvc_value AS REPORT_NAME
     , nvp.pvc_value AS  REPORT_PARAM
     , pr.name_full_formatted AS UPDATED_BY
     , nvp.updt_dt_tm
from name_value_prefs nvp
  /* Link to the same level PVC, but we want the REPORT_NAME */
     inner join  name_value_prefs nvpc
             on nvpc.parent_entity_id = nvp.parent_entity_id
            and nvpc.parent_entity_name = nvp.parent_entity_name
            and nvpc.active_ind = 1
            and nvpc.pvc_name = 'REPORT_NAME' 
     inner join prsnl pr
             on pr.person_id = nvp.updt_id
  /* link to detail_prefs as an intermediary step to get to PVC's of parents
     depends on what is used n nvp.parent_entity_name below */
     inner join detail_prefs dpref
             on dpref.detail_prefs_id = nvp.parent_entity_id
  /* link to application table to get human-readable application name */
     inner join application a
             on  a.application_number = dpref.application_number
  /* link to codeset to get human-readable position description
  THIS WILL CAPTURE POSITION-LVEL prefs only */
     inner join code_value cv
             on cv.code_value = dpref.position_cd
            and cv.code_set = 88
            and cv.active_ind = 1
  /* Detail_pref is part of a view, so let us get the view_pref row
     The view_pref shares the same attributes below as the linked detail_pref row */
    inner join view_prefs vpref
            on vpref.view_name = dpref.view_name
           and vpref.view_seq = dpref.view_seq
           and vpref.application_number = dpref.application_number
           and vpref.position_cd = dpref.position_cd
           and vpref.prsnl_id = dpref.prsnl_id
           and vpref.active_ind = 1 
  /* Link to PVC of parent to get caption name */
     inner join name_value_prefs nvpr
             on nvpr.parent_entity_name = 'VIEW_PREFS'
            and nvpr.parent_entity_id = vpref.view_prefs_id
            and nvpr.pvc_name = 'VIEW_CAPTION'
  /* Link to PVC of parent to get display sequence */
     inner join name_value_prefs nvpq
             on nvpq.parent_entity_name = 'VIEW_PREFS'
            and nvpq.parent_entity_id = vpref.view_prefs_id
            and nvpq.pvc_name = 'DISPLAY_SEQ'           
  /* Define the search criteria here. */
where nvp.pvc_name = 'REPORT_PARAM'
   and nvp.pvc_value like '%static_content%'  /* "*I:*"  */
   and nvp.parent_entity_name = 'DETAIL_PREFS' 
order by COMPONENT_CAPTION_NAME,REPORT_NAME,position,a.description,a.application_number
;
