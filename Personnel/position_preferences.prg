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
             , (inner join detail_prefs dref
                         on dref.detail_prefs_id = nvp.parent_entity_id
                        AND dref.position_cd > 0       ;; Position-level pref (may include inactive positions */
                        AND dref.prsnl_id = 0)         ;; Do not touch user-level prefs
           where cnvtupper(nvp.pvc_name) in ("REPORT_PARAM","REPORT_NAME")
             AND cnvtupper(nvp.pvc_value) in ("*P647*" , "*PROD*", "*PRD*")
             AND nvp.parent_entity_id > 0)


/* Audit query */
/* Position-level prefs that have prod Discern Report links */
select /* prefrence level: application, position, user */
       vref.application_number
     , vref.position_cd   ;; position context 
     , vref.prsnl_id      ;; user context
     , a.description
     , position=cv.display
     /* View-level */
     , VIEW_LEVEL=vref.frame_type
     , VIEW_NAME=vref.view_name
     , VIEW_CAPTION=nvpview.pvc_value
     , VIEW_SEQ=cnvtint(nvpseq.pvc_value) /* pvc_value is text, and sorted accrdingly: 36 is before 4! */
     /* Detail level */
     , dref.view_name
     , dref.view_seq
     , dref.comp_name
     , dref.comp_seq
     , dref.position_cd ;; position context
     , dref.prsnl_id    ;; user context
     /* Debug results here */
     , VIEW_CAPTION_NVP_ID=nvpview.name_value_prefs_id 
     , VIEW_CAPTION=nvpview.pvc_value
     , DISPLAY_SEQ_NVP_ID=nvpseq.name_value_prefs_id
     , DISPLAY_SEQ=nvpseq.pvc_value
     , REPORT_NAME_NVP_ID=nvpr.name_value_prefs_id
     , REPORT_NAME=nvpr.pvc_value
     /* Preferences of interest */
     , OBJECT_NAME_NVP_ID=nvp.name_value_prefs_id
     , OBJECT_NAME=nvp.pvc_name
     , OBJECT_VALUE=nvp.pvc_value
from name_value_prefs nvp
   /* 
	  name_value_prefs store name:value tuples 
	  
      There sre two attributes in this table, parent_entity_id and parent_entity_ame
         that refer to the preference tab/component hierarchy in prefmaint.exe
		 TAB is similar to a folder in the hierarchy
		 COMPONENT is the lowest in the hierarchy, which stored folder-level settings
		   (parent is VIEW_COMP_PREFS), or preferences (parent could be APP_PREFS, DETAIL_PREFS, VIEW_PREFS)
		    see PowerOrders hierarchy
         OR the preference context (application, position or user)
	  Note that when you right-click on a tab, you are asked to add a tab or a preference. 	 
	     If the tab is the las in the hierrchy, you are asked to add a component or preference
		
      Preference CONTEXT tables are names X_prefs -- APP_PREFS, DETAIL_PREFS, VIEW_PREFS
      Preference HIERARCHY table is VIEW_COMP_PREFS
	  
      The application context is a an attribute of every CONTEXT table 
        so preference is either:
    		application only  --  only application_nmber is non-zero
         	application-position -- both application_number and position_cd are non-zero
			aplpication-user -- both application_number and prsnl_id are non-zero
    */
  ;; link to view_prefs to get the application context and position context
  , (inner join detail_prefs dref
             on dref.detail_prefs_id = nvp.parent_entity_id
            and dref.position_cd > 0.0  ;; Position-level pref
            and dref.prsnl_id = 0.0 )   ;; Do not touch user-level prefs
  ;; mapping of component to view. Note that we need to define application,position and user-level pref.
  ;; This table does not have frame_ref
  , (inner join view_comp_prefs vcref
             on vcref.view_name = dref.view_name
            and vcref.view_seq = dref.view_seq
            and vcref.comp_name = dref.comp_name /* where is this used? */
            and vcref.comp_seq = dref.comp_seq
            and vcref.application_number = dref.application_number
            and vcref.position_cd = dref.position_cd
            and vcref.prsnl_id = dref.person_id)
  ;; Gte the corresponding view. Note that we need to define application,position and user-level pref.
  ;; This is a circuitous way of getting frame_ref, but we eed to get thuis level so we can see which ones are defined below it.
  , (inner join view_prefs vref
             on vref.view_name = vcref.view_name
            and vref.view_seq = vcref.view_seq
            and vref.application_number = vcref.application_number
            and vref.position_cd = vcref.position_cd
            and vref.prsnl_id = vcref.prsnl_id )
  ;; Get the NVP details of above view.  We are interetsered in the VIEW_CAPTION attribute
  , (inner join name_value_prefs nvpview
            on nvpview.parent_entity_id = vref.view_prefs_id
           and nvpview.pvc_name = 'VIEW_CAPTION')     /* This is component-specific */
 , (inner join name_value_prefs nvpseq
            on nvpseq.parent_entity_id = vref.view_prefs_id
           and nvpseq.pvc_name = 'DISPLAY_SEQ')       /* This is component-specific */
  ; In the same level, get the corresponding REPORT_NAME that belogs to the same PREF grouping.
  ; This will have the same parent_entity_id
  , (inner join name_value_prefs nvpr
            on nvpr.parent_entity_id = nvp.parent_entity_id
           and nvpr.parent_entity_name = 'DETAIL_PREFS' /* component spcific */
           and nvpr.pvc_name = 'REPORT_NAME')           /* component spcific */
  ;; link to application table to get human-readable application name
  , (inner join application a
             on  a.application_number = dref.application_number)
  ;; link to codeset to get human-readable position description
  , (inner join code_value cv
             on cv.code_value = dref.position_cd
            and cv.code_set = 88
            and cv.active_ind = 1)
;; start here to define the preference and the value
where cnvtupper(nvp.pvc_name) in ("REPORT_PARAM","REPORT_NAME")
  AND cnvtupper(nvp.pvc_value) in ("*P647*" , "*PROD*", "*PRD*")
  AND nvp.parent_entity_id > 0
;;  and dref.position_cd = 441.00
order by
       vref.frame_type desc
     , vref.view_name
     , nvpview.pvc_value
     , a.description
     , cnvtupper(cv.display)
     , vref.prsnl_id
     , cnvtint(nvpseq.pvc_value)
with maxtime=300 ;; always good to have a query circuit-breaker
go
