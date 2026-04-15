import requests, json, sys
from PIL import Image
print("deps: OK")

API_KEY = "2f70a6be-6c63-4599-a0e6-666359a3ce81"
resp = requests.get(
    "https://api.pixellab.ai/v2/balance",
    headers={"Authorization": f"Bearer {API_KEY}"}
)
print(f"Status: {resp.status_code}")
print(json.dumps(resp.json(), indent=2))
