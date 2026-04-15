with source as (
    select * from {{ source('polymarket_raw_data', 'markets') }}
),

renamed as (
    select
        -- Identificador Único (Basado en el JSON)
        cast(slug as string) as market_slug,
        
        -- Dimensiones
        cast(title as string) as market_title,
        cast(url as string) as market_url,
        
        -- Métricas
        cast(volume as float64) as total_volume,
        cast(volume_24h as float64) as volume_last_24h,
        cast(liquidity as float64) as liquidity,
        
        -- Estructuras anidadas
        categories, -- Array de strings ["politics", "geopolitics", ...]
        outcomes,   -- Array de objetos [{"title": "...", "probability": ...}, ...]
        
        -- Metadata
        cast(extraction_timestamp as timestamp) as data_extracted_at
    from source
)

select * from renamed