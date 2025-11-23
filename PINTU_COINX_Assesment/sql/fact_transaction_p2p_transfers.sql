create or replace table `datamart.fact_transactions_p2p_transfers` as 

with clean_transfer as (
  select
    transfer_id
    ,sender_id
    ,receiver_id
    ,token_id
    ,cast(amount as bignumeric) amount
    ,status
    ,datetime(
          parse_timestamp('%Y-%m-%d %H:%M:%S', transfer_created_time),
          'Asia/Jakarta'
      ) AS transfer_created_time -- convert to Jakarta / WIB Time
    ,datetime(
          parse_timestamp('%Y-%m-%d %H:%M:%S', transfer_updated_time),
          'Asia/Jakarta'
      ) AS transfer_updated_time -- convert to Jakarta / WIB Time
    ,row_number() over(partition by transfer_id order by 
      datetime(
          parse_timestamp('%Y-%m-%d %H:%M:%S', transfer_created_time),
          'Asia/Jakarta'
      )) rn
  from  `raw_transaction.raw_p2p_transfers`
  where status = 'SUCCESS' -- get the success transfer only
  and sender_id != receiver_id -- to elim if the transfer to the same user_id
)

,raw_transfer as (
  select
    transfer_id
    ,sender_id
    ,receiver_id
    ,token_id
    ,cast(amount as bignumeric) amount
    ,status
    ,transfer_created_time
    ,transfer_updated_time
  from  clean_transfer
  where rn = 1 -- elminate dupplicate transfer_id and get the first info
)

,dim_daily_price_token as (
  select
    date(trade_created_time) price_date
    ,token_id
    ,sum(trade_quantity*trade_price_usd) / sum(trade_quantity) daily_vwap_usd
  from
    datamart.fact_transactions_trades
  where status = 'FILLED'
  group by
    1, 2
)

,raw_transfer_price_before as (
  select
    p.transfer_id
    ,daily_vwap_usd
    ,t.price_date
  from raw_transfer p
  left join dim_daily_price_token t on p.token_id = t.token_id 
    and date(p.transfer_created_time) >= date(t.price_date)
  qualify row_number() over(partition by p.transfer_id order by t.price_date desc) = 1
)

,raw_transfer_price_after as (
  select
    p.transfer_id
    ,daily_vwap_usd
    ,t.price_date
  from raw_transfer p
  left join dim_daily_price_token t on p.token_id = t.token_id 
    and date(p.transfer_created_time) <= date(t.price_date)
  qualify row_number() over(partition by p.transfer_id order by t.price_date asc) = 1
)

,base as (
  select
    p.*
    ,case
      when token_id = 'USDT' then 1
      else coalesce(pb.daily_vwap_usd,pa.daily_vwap_usd)
    end price_in_usd -- using the last price before transfer time, if its null get the next nearest date price
    ,case
      when token_id = 'USDT' then date(p.transfer_created_time)
      else coalesce(pb.price_date,pa.price_date)
    end price_in_usd_date -- using the last price before transfer time, if its null get the next nearest date price
    ,amount 
      * 
      case
        when token_id = 'USDT' then 1
        else coalesce(pb.daily_vwap_usd,pa.daily_vwap_usd)
      end as transfer_value_usd
    
  from raw_transfer p
  left join raw_transfer_price_before pb on p.transfer_id = pb.transfer_id
  left join raw_transfer_price_after pa on p.transfer_id = pa.transfer_id
)

,percentile as (
  select
    approx_quantiles(transfer_value_usd, 1000)[OFFSET(999)] p999
  from base
)

select 
  b.*
  ,case
      when b.transfer_value_usd >= p.p999 then true
      else false
  end is_suspicious_transfer_dynamic_threshold
  ,case
      when b.transfer_value_usd >= 1500000 then true
      else false
  end is_suspicious_transfer_1500000_threshold
from base b
cross join percentile p 

