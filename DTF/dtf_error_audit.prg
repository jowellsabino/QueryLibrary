select
/* Group-gathering statistics
;       dtf.dtf_ops_job
;      , NUM_PT=count(distinct dtf.person_id)
;      , NUM_NOT=count(distinct dtf.chb_dtf_notify_id)
*/
       dtf.chb_dtf_notify_id
     , Patient_Name=p.name_full_formatted
     , CSN=ea.alias
     , ENCNTR_ACTIVE=e.active_ind
     , ENCTR_UPDT_DT_TM=e.updt_dt_tm
     , LOCATION=uar_get_code_display(e.loc_nurse_unit_cd)
     , dtf.encntr_id
     , DTF_CREATE_DT_TM=dtf.create_dt_tm
     , MRN=pa.alias
     , dtf.person_id
     , dtferr.error_code
     , dtferr.exception_dt_tm
     , dtferr.error_message
     , dtf.*
from v500_cust.chb_dtf_notify dtf
  , (inner join v500_cust.forward_event_exception_log dtferr
             on dtferr.param_signer_id = dtf.chb_dtf_notify_id
           and dtferr.error_code != 200)
  , (inner join person p
             on p.person_id = dtf.person_id)
  , (inner join person_alias pa
             on pa.person_id = dtf.person_id
            and pa.active_ind = 1
            and pa.end_effective_dt_tm > sysdate)
  , (inner join code_value person_alias
             on person_alias.code_value = pa.alias_pool_cd
            and person_alias.display = 'CHB_MRN' ;; 3110551
            and person_alias.active_ind = 1)
  , (inner join encounter e
             on e.encntr_id = dtf.encntr_id)
  ;; Change this to left join for systemtestonly patients w/o a proper encounter alias.
  ;; Rremove the qualification for active_in d= 1 so it will not disqualify ncounters that are
  ;; cancelled (but powerplans written on it -- Cerner does not disqialify powerplans
  ;; as activity that prevents encounter cancellation)
  , (left join encntr_alias ea
             on ea.encntr_id = e.encntr_id
  ;          and ea.active_ind = 1
            and ea.end_effective_dt_tm > sysdate)
  ;; Make this an inner join so we only join on CSN, not other encounter-level aliases (e.g. MRN and HAR)
  ;; this will disqualify encounters that are cancelled (but powerplans written on it -- Cerner does not disqialify powerplans
  ;; as activity that prevents encounter cancellation
  , (inner join code_value encntr_alias_type
             on encntr_alias_type.code_value = ea.encntr_alias_type_cd
            and encntr_alias_type.cdf_meaning = 'FIN NBR' ;; 1077
            and encntr_alias_type.active_ind = 1
            and encntr_alias_type.code_set = 319)
where dtf.notify_status_cd in (select code_value
                                 from code_value
                                where cdf_meaning in ('ORDERED','PENDING') ;; 1407,1408
                                  and code_set = 1305)
  and dtf.active_ind = 1
  and dtf.create_dt_tm > sysdate - 10 ;; make this greater than parameter used in chb_dtf_send_notifications opsjob
/* Debug 
;  and dtf.person_id =     2099654.00
; and dtf.catalog_cd =   903980565.00
; For gathering statistics
*/
/* Group-gathering 
;group by dtf.dtf_ops_job
;order by dtf.dtf_ops_job;
*/
order by dtf.create_dt_tm DESC,dtf.person_id,dtf.encntr_id,dtferr.exception_dt_tm ;;
with maxrec=5000,maxtime=1000,format(date,";;q")
go