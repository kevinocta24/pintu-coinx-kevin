select
  trade_id
  ,count(trade_id) total_duplicate
from  `raw_transaction.raw_trades`
group by 1
having count(trade_id) > 1 -- to capture transfer_id that being recorded more than once