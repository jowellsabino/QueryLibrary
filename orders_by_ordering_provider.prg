/* Orders written with the provider as the ordering provider (and thus RTE is routed to this provider) */
select o.order_id,o.order_mnemonic
    , EVENT=uar_get_code_display(ce.event_cd)
    , CSN=ea.alias
    , ce.event_title_text
    , ce.result_val
    , ce.*
from order_action oa
  , (inner join orders o
             on o.order_id = oa.order_id)
      , (inner join encntr_alias ea
                 on ea.encntr_id = o.encntr_id
                and ea.active_ind = 1
                and ea.end_effective_dt_tm > sysdate
                and ea.encntr_alias_type_cd in (select code_value
                                                  from code_value
                                                 where code_set = 319
                                                   and cdf_meaning = 'FIN NBR'))
       , (inner join clinical_event ce
                  on ce.order_id = o.order_id
                 and ce.valid_until_dt_tm > sysdate
                 and ce.view_level = 1
                and ce.event_class_cd in (select code_value
                                            from code_value
                                           where code_set = 53
                                             and cdf_meaning in ('NUM','TXT','MDOC','MBO'))
                 /* Not endorsed by anyone */
                 and not exists (select 1
                                   from ce_event_prsnl cep
                                  where cep.event_id = ce.event_id
                                     and cep.valid_until_dt_tm > sysdate
                                     and cep.action_type_cd in (select code_value
                                                                  from code_value
                                                                 where code_set = 21
                                                                   and cdf_meaning in ('ENDORSE','ENDORSESAVE'))))
        /* Endorsed by someone */
;        , (inner join ce_event_prsnl cep
;                   on cep.event_id = ce.event_id
;                                     and cep.action_type_cd = (select code_value
;                                                                 from code_value
;                                                                where code_set = 21
;                                                                  and cdf_meaning in ('ENDORSE','ENDORSESAVE')))
        /* This will not work after 60 days (purge window) */
       , (inner join ce_event_action cea
                  on cea.event_id = ce.event_id)
        , (inner join order_catalog oc
                   on oc.catalog_cd = o.catalog_cd
                  and o.orderable_type_flag = 0
                  and o.catalog_type_cd  in (select code_value
                                                  from code_value
                                                 where code_set = 6000
                                                   and cdf_meaning in ('GENERAL LAB','RADIOLOGY')))
where oa.action_type_cd in (select code_value
                             from code_value
                            where code_set = 6003
                              and cdf_meaning = 'ORDER')
   and oa.action_dt_tm >  sysdate - 60 ;between sysdate - 70 and sysdate - 60 /* Adjust, RTE gets purged after 60 days */
   and oa.order_provider_id = (select person_id
                                from prsnl
                               where username = 'CHXXXXXX') /* Provider, CHANGE */
with maxtime=30
go
 
