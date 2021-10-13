import datetime
import socket

host = socket.gethostname()
now = datetime.datetime.now()
nowS = now.strftime("%m/%d/%Y, %H:%M:%S")

import urllib3
http=urllib3.PoolManager()
url = 'http://Echo4Advini.eu-de.mybluemix.net/v1/echo?host=' + host + '&time=' + nowS
r = http.request('GET', url)
print r.status

