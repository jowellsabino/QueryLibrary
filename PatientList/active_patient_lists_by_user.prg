/* Get active patient list */
SELECT
VP.VIEW_PREFS_ID
;;,VP.ACTIVE_IND
;;,VP.APPLICATION_NUMBER
,a.description
;;,VP.POSITION_CD
;;,VP.PRSNL_ID
;;,VP.FRAME_TYPE
;;,VP.VIEW_NAME
,VP.VIEW_SEQ
,VP.UPDT_DT_TM
,VP.UPDT_TASK
, Patient_List_Type=cv.display
, dpl.description
, dpl.patient_list_id
, dpl.name
, nvp.*
FROM VIEW_PREFS VP
, (inner join name_value_prefs nvp
           on nvp.parent_entity_id = vp.view_prefs_id
          and nvp.pvc_name = 'VIEW_CAPTION')
, (inner join dcp_patient_list dpl
           on dpl.owner_prsnl_id = vp.prsnl_id
          and dpl.name = nvp.pvc_value) /* not very efficient - stores by name!!! ??? */
, (inner join code_value cv on cv.code_value = dpl.patient_list_type_cd)
, (inner join application a on a.application_number = vp.application_number)
WHERE VP.APPLICATION_NUMBER > 0
AND VP.POSITION_CD = 0
AND VP.PRSNL_ID  = 8531805; ;; person_id of user here 
AND VP.FRAME_TYPE = "PTLIST"
AND VP.VIEW_NAME = "PATLISTVIEW"
AND VP.ACTIVE_IND = 1
ORDER BY a.description,VP.VIEW_SEQ ASC
go