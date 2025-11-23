select
  date(date_key) date_blank
  ,'Blank - Data Transfer Not Found' remarks
from 
  datamart.dim_date dd
left join  `raw_transaction.raw_p2p_transfers` rt on dd.date_key = date(transfer_created_time)
where date(transfer_created_time) is null
group by 1