/* Task purge audit, per task */
SELECT MRN=pa.alias
     , CSN=ea.alias
     ,   TASK_TYPE = cvtt.display
     , ot.task_description
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
;     ,  task_count=count(ta.task_id)
; --    , max(ta.updt_dt_tm) AS latest_updt/* This is expensive to do, in an already expensive query */
; --    , min(ta.updt_dt_tm) AS earliest_updt/* This is expensive to do, in an already expensive query */
      , ta.*
 FROM task_activity ta
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
;  and cvtt.display = 'Phone Msg'
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
, (INNER
 JOIN order_task ot
   on ot.task_type_cd = ta.task_type_cd
  and ot.task_activity_cd = ta.task_activity_cd
)
 , (inner join person p
             on p.person_id = ta.person_id)
  , (inner join person_alias pa
             on pa.person_id = p.person_id
            and pa.active_ind = 1
            and pa.end_effective_dt_tm > sysdate)
  , (inner join code_value person_alias
             on person_alias.code_value = pa.alias_pool_cd
            and person_alias.display = 'CHB_MRN' ;; 3110551
            and person_alias.active_ind = 1)
  , (inner join encounter e
             on e.encntr_id = ta.encntr_id)
  ;; Change this to left join for systemtestonly patients w/o a proper encounter alias.
  ;; Rremove the qualification for active_in d= 1 so it will not disqualify ncounters that are
  ;; cancelled (but powerplans written on it -- Cerner does not disqialify powerplans
  ;; as activity that prevents encounter cancellation)
  , (inner join encntr_alias ea
             on ea.encntr_id = e.encntr_id
            and ea.active_ind = 1
            and ea.end_effective_dt_tm > sysdate
            and ea.encntr_alias_type_cd in (select code_value
                                              from code_value
                                             where code_set = 319
                                               and cdf_meaning = 'FIN NBR'))
WHERE ta.task_status_cd   IN (SELECT code_value
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
  AND ta.task_type_cd IN (SELECT code_value
                            FROM code_value
                           WHERE  code_set = 6026
                             AND display_key =  'PHYSICALTHERAPY') ;'GIAMBULATORY')
  AND ta.updt_dt_tm < sysdate - 365 ;1625 /* Note that for dropped and finalized tasks, set to 31.  For active tasks, set to 365 */
;GROUP BY cvtt.display /* Task type */
;     , cve.field_value
;     , cvts.display /* Task status */
; --    , cve.field_value /* Task purge status in tl_purge_criteria table */
; --    , e.encntr_status_cd
; --    , ta.ACTIVE_IND   /* Task active indicator (source of defect) */
;ORDER BY TASK_TYPE,PURGETASKSTATUS
go;