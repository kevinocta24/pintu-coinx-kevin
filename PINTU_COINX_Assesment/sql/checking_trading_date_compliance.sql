select
  date(date_key) date_blank
  ,'Blank - Data Trading Not Found' remarks
from 
  datamart.dim_date dd
left join  `raw_transaction.raw_trades` rt on dd.date_key = date(trade_created_time)
where date(trade_created_time) is null
group by 1