import urllib.request, json

data = json.dumps({'username':'admin','password':'admin123'}).encode()
r = urllib.request.Request('http://127.0.0.1:8000/auth/login', data=data, headers={'Content-Type':'application/json'})
token = json.loads(urllib.request.urlopen(r).read())['access_token']

r2 = urllib.request.Request('http://127.0.0.1:8000/alerts?date=today', headers={'Authorization':f'Bearer {token}'})
resp = json.loads(urllib.request.urlopen(r2).read())
print('Total alerts today:', resp['total'])
for a in resp['data'][:10]:
    print(f"  {a['driver_name']} - {a['alert_type']} {a['severity']} - {a['created_at']}")
