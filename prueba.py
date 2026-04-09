import urllib.request
import json
import time

# URL con filtros de Activos y No Cerrados
base_url = "https://gamma-api.polymarket.com/events?closed=false&active=true&limit=100"

headers = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    "Accept": "application/json, text/plain, */*",
    "Origin": "https://polymarket.com",
    "Referer": "https://polymarket.com/",
}

all_active_events = []
offset = 0

print("Descargando solo mercados ACTIVOS...")

try:
    while True:
        url = f"{base_url}&offset={offset}"
        req = urllib.request.Request(url, headers=headers)
        
        with urllib.request.urlopen(req) as response:
            data = json.loads(response.read())
            
            if not data or len(data) == 0:
                break
                
            all_active_events.extend(data)
            print(f"Obtenidos {len(all_active_events)} mercados activos...")
            
            # Si la respuesta trae menos de 100, llegamos al final de los activos
            if len(data) < 100:
                break
            
            offset += 100
            time.sleep(0.5)

    print(f"\n✅ Total final de mercados activos: {len(all_active_events)}")

    # Ejemplo: Ver los títulos de los primeros 5
    for ev in all_active_events[:5]:
        print(f"- {ev.get('title')}")

except Exception as e:
    print(f"Error: {e}")