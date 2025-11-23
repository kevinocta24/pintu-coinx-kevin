select
  transfer_id
  ,count(transfer_id) total_duplicate
from  `raw_transaction.raw_p2p_transfers`
group by 1
having count(transfer_id) > 1 -- to capture transfer_id that being recorded more than once