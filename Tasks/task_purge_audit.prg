/* ALL Active Tasks Purge after 365 days*/ 
SELECT TASK_TYPE = cvtt.display
     ,  PURGETASKSTATUS=evaluate(cve.field_value
              ,'1','Finalized'
              ,'2','Dropped'
              ,'4','Active'
              ,'Unknown')
     ,  TASK_STATUS=cvts.display  /* Can be confusing to run for all task types, but can be done */
     /* This is the alternative rather than joiing explicitly on tl_purge_crtiteria table */
;--     , CASE cve.field_value
;--            WHEN  '1' THEN 'Finalized'
;--            WHEN  '2' THEN 'Dropped'
;--            WHEN  '4' THEN 'Active'
;--            ELSE  'Unknown'
;--       END AS PurgeTaskStatus
;--     , ta.ACTIVE_IND  /* Task active indicator (source of defect) */
     ,  task_count=count(ta.task_id)
; --    , max(ta.updt_dt_tm) AS latest_updt/* This is expensive to do, in an already expensive query */
; --    , min(ta.updt_dt_tm) AS earliest_updt/* This is expensive to do, in an already expensive query */
 FROM task_activity ta
; Uncomment if needed to purge only tasks on discharged encounter 
;, (INNER
; JOIN encounter e
;   ON e.encntr_id = ta.encntr_id
;            AND e.encntr_status_cd+0 IN (SELECT code_value
;                                           FROM code_value
;                                          WHERE code_set = 261
;                                            AND cdf_meaning IN ('DISCHARGED','CANCELLED'))
;)
, (INNER
 JOIN code_value cvtt
   ON cvtt.CODE_VALUE  = ta.TASK_TYPE_CD
  AND cvtt.code_set = 6026
;  and cvtt.display = 'Phone Msg' ; Debug - Phone Msg type only
 )
, (INNER
 JOIN code_value cvts
   ON cvts.CODE_VALUE  = ta.TASK_status_CD
  AND cvts.code_set = 79
)
, (INNER
 JOIN code_value_extension cve
   ON cve.code_value = cvts.code_value
)
WHERE ta.task_status_cd+0 IN (SELECT code_value
                                FROM code_value
                               WHERE code_set = 79
                                 AND active_ind = 1
                                 AND code_value IN (SELECT code_value
                                                      FROM code_value_extension
                                                     WHERE field_value IN ('4')) )/* 1- Cancelled, Complete, Deleted, Discontinued (task statuses)*/
                                                     /* 2 - Dropped; 4 - Delivered, In Error, On Hold, Opened
                                                                       , Overdue, Pending, Read, Rework, Suspended
                                                                       , Refused, Pending Validation, Recalled */
                                                    /* Dropped is set by the retention time configured in the order-task tool */
                                                    /* Since Dropped/Finlaized tasks are purged if > 30 days, and active tasks purged if > 365, be sure
                                                        to  change qualifiers for field_value and updt_dt_tm below */
; Debug  - medication tasks only
;--  AND ta.task_type_cd+0 IN (SELECT code_value
;--                              FROM code_value
;--                             WHERE  code_set = 6026
;--                               AND display_key =  'MEDICATION')
  AND ta.updt_dt_tm < sysdate - 365 ;1625 /* Note that for dropped and finalized tasks, set to 31.  For active tasks, set to 365 */
GROUP BY cvtt.display /* Task type */
     , cve.field_value
     , cvts.display /* Task status */
; --    , cve.field_value /* Task purge status in tl_purge_criteria table */
; --    , e.encntr_status_cd
; --    , ta.ACTIVE_IND   /* Task active indicator (source of defect) */
ORDER BY TASK_TYPE,PURGETASKSTATUS
go;