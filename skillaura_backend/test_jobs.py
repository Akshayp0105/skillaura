import httpx, json

print("=== Testing /jobs/search ===")
try:
    r = httpx.get(
        "http://localhost:8000/jobs/search",
        params={"query": "python developer", "country": "in", "results_per_page": "3"},
        timeout=15,
    )
    print("Status:", r.status_code)
    print("Body (first 500 chars):", r.text[:500])
    if r.status_code == 200:
        d = r.json()
        jobs = d.get("jobs", [])
        print("Total:", d.get("total", 0))
        for j in jobs[:3]:
            print(f"  - {j['title']} @ {j['company']} | match:{j['match_score']}%")
except Exception as e:
    print("ERROR:", e)

print()
print("=== Testing /jobs/suggest ===")
try:
    r2 = httpx.get(
        "http://localhost:8000/jobs/suggest",
        params={"query": "flutter", "country": "in"},
        timeout=8,
    )
    print("Status:", r2.status_code)
    d2 = r2.json()
    print("Suggestions:", d2.get("suggestions", [])[:5])
except Exception as e:
    print("ERROR:", e)

print()
print("=== Done ===")
