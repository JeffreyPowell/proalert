#!/usr/bin/env python

import MySQLdb
import datetime
import urllib2
import os

try:
    from configparser import ConfigParser
except ImportError:
    from ConfigParser import ConfigParser

config = ConfigParser()
config.read('/opt/proadmin/proadmin-master/config.ini')

servername = config.get('db', 'server')
username = config.get('db', 'user')
password = config.get('db', 'password')
dbname = config.get('db', 'database')

t = datetime.datetime.now().strftime('%s')

cnx = MySQLdb.connect(host=servername, user=username, passwd=password, db=dbname)
cnx.autocommit(True)
cursorread = cnx.cursor()
query = ("SELECT id, name, url, port FROM systems")
cursorread.execute(query)
results =cursorread.fetchall()
cursorread.close()
cnx.close()
  
for i in results:
  system_id = i[0]
  system_name = i[1]
  system_url = i[2]
  system_port = i[3]



 
  
    os.system('/usr/bin/rrdtool update '+filename+" "+str(t)+':'+str(data))
