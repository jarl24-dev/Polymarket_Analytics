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

with raw_outcomes as (
    select
        market_slug,
        outcome.element.title as outcome_title,
        cast(outcome.element.probability as float64) as probability,
        cast(outcome.element.day_change as float64) as day_change,
        data_extracted_at
    from {{ ref('stg_polymarket_markets') }},
    unnest(outcomes.list) as outcome
    
    {% if is_incremental() %}
      -- Filtramos antes de agrupar para mejorar el rendimiento
      where data_extracted_at > (select max(data_extracted_at) from {{ this }})
    {% endif %}
)

select
    market_slug,
    outcome_title,
    -- Agrupamos para eliminar duplicados técnicos
    max(probability) as probability,
    max(day_change) as day_change,
    data_extracted_at
from raw_outcomes
group by 1, 2, 5