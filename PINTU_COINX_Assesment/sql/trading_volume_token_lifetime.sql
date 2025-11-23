select
  token_id
  ,sum(trade_value_usd) total_trade
from `datamart.fact_transactions_trades` f
group by 1
order by 2 desc