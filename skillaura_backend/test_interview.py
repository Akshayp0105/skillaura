import httpx

endpoints = [
    '/coding/companies',
    '/aptitude/categories', 
    '/mocktest/domains',
    '/coding/questions/google',
    '/aptitude/questions/quantitative',
    '/mocktest/questions/dsa',
]

for ep in endpoints:
    try:
        r = httpx.get(f'http://localhost:8000{ep}', timeout=5)
        data = r.json()
        count = len(data) if isinstance(data, list) else '(dict)'
        print(f'{r.status_code} {ep} -> {count} items')
    except Exception as e:
        print(f'ERROR {ep}: {e}')
