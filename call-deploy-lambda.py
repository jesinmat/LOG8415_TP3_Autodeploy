import requests
import json
from hmac import HMAC
from hashlib import sha256

url = 'http://' + open('tmp/lb-url.txt').read().splitlines()[0] + '/lambda/deploy'
secret = ''
secretsFile = open('lambda/secrets.sh', 'r')
for line in secretsFile:
    line = line.strip().split('=')
    if line[0] == "AWS_SECRET_KEY":
        secret = line[1].replace("\"", "")
        break

body = {'ref': 'branch/main', 'after': '6c0709a43631e'}
body = json.dumps(body)
expected_sign = HMAC(key=secret.encode(), msg=body.encode(), digestmod=sha256).hexdigest()
headers = {'content-type': 'application/json', 'x-hub-signature-256': 'sha256='+expected_sign}

requests.post(url, data=body, headers=headers)