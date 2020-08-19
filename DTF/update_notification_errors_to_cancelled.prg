/* Update DTF notifications that cannot be processed to "Cancelled" 
   This is run after the audit query, to find out root cause
   Run in the backend instead of DVD
*/
update  into v500_cust.chb_dtf_notify
set notify_status_cd = 1400,  ;; "Cancelled", since no notification was actually sent as a result of the error
updt_id = 8531805.00,
updt_dt_tm = cnvtdatetime(curdate,curtime3)
where chb_dtf_notify_id in (select dtf.chb_dtf_notify_id
                             from v500_cust.chb_dtf_notify dtf
                            where dtf.notify_status_cd in (1407,1408) ;; one sub-select is enough....
                             and dtf.create_dt_tm > sysdate - 10
                             and dtf.active_ind = 1)