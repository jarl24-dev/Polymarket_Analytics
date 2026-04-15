{{ 
    config(
        materialized='incremental',
        unique_key=['market_slug', 'data_extracted_at'],
        incremental_strategy='merge'
    ) 
}}

with raw_stats as (
    select
        market_slug,
        total_volume,
        volume_last_24h,
        liquidity,
        data_extracted_at
    from {{ ref('stg_polymarket_markets') }}

    {% if is_incremental() %}
      where data_extracted_at > (select max(data_extracted_at) from {{ this }})
    {% endif %}
)

select
    market_slug,
    max(total_volume) as total_volume,
    max(volume_last_24h) as volume_last_24h,
    max(liquidity) as liquidity,
    data_extracted_at
from raw_stats
group by market_slug, data_extracted_at