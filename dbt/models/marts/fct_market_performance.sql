{{ 
    config(
        materialized='incremental',
        unique_key=['market_slug', 'outcome_title', 'data_extracted_at'],
        incremental_strategy='merge',
        partition_by={
            "field": "data_extracted_at",
            "data_type": "timestamp",
            "granularity": "day"
        },
        cluster_by=["market_slug"]
    ) 
}}

with markets as (
    select * from {{ ref('int_polymarket_markets_dim') }}
),
stats as (
    select * from {{ ref('int_polymarket_market_stats_fct') }}
    {% if is_incremental() %}
      where data_extracted_at > (select max(data_extracted_at) from {{ this }})
    {% endif %}
),
outcomes as (
    select * from {{ ref('int_polymarket_outcomes_fct') }}
    {% if is_incremental() %}
      where data_extracted_at > (select max(data_extracted_at) from {{ this }})
    {% endif %}
)

select
    m.market_slug,
    m.market_title,
    array_to_string(m.categories, ', ') as categories_list,
    o.outcome_title,
    o.probability,
    s.total_volume,
    s.liquidity,
    o.data_extracted_at
from outcomes o
left join markets m on o.market_slug = m.market_slug
left join stats s on o.market_slug = s.market_slug 
    and o.data_extracted_at = s.data_extracted_at