#!/usr/bin/env python

def send_email(config, recipient, subject, body):

    import smtplib

    servername = config.get('db', 'server')
    username   = config.get('db', 'user')
    password   = config.get('db', 'password')
    dbname     = config.get('db', 'database')

    cnx = MySQLdb.connect(host=servername, user=username, passwd=password, db=dbname)
    cursorread = cnx.cursor()
    query = ("SELECT value FROM conf WHERE name LIKE 'smtp_%' ORDER BY id;")
    cursorread.execute(query)
    results =cursorread.fetchall()
    cursorread.close()

    smtp_host           = str(results[0][0])
    smtp_auth_username  = str(results[1][0])
    smtp_auth_password  = str(results[2][0])
    smtp_from           = str(results[3][0])
    smtp_host_port      = str(results[4][0])

    #print smtp_host
    #print smtp_auth_username
    #print smtp_auth_password
    #print smtp_from
    #print smtp_host_port

    TO = recipient if type(recipient) is list else [recipient]
    SUBJECT = subject
    TEXT = body
    FROM = smtp_from

    # Prepare actual message
    message = """From: %s\nTo: %s\nSubject: %s\n\n%s
    """ % (FROM, ", ".join(TO), SUBJECT, TEXT)

    try:
        
    	server = smtplib.SMTP(smtp_host, int(smtp_host_port))
    	server.ehlo()
    	server.starttls()
    	server.login(smtp_auth_username, smtp_auth_password)
        
    	server.sendmail(FROM, TO, message)
       
    	server.close()
    	print 'successfully sent the mail'
    except:
    	print "failed to send mail"

def read_config():

    try:
        from configparser import ConfigParser
    except ImportError:
        from ConfigParser import ConfigParser

    config_file = ConfigParser()
    config_file.read('/opt/proalert/proalert-master/config.ini')

    return config_file

def check_systems(config, interval):

	servername = config.get('db', 'server')
	username   = config.get('db', 'user')
	password   = config.get('db', 'password')
	dbname     = config.get('db', 'database')

	today = datetime.date.today()

	message_subject_template = "Prometheus Alert - [[system-name]] <[[system-tier]]>  [[date]]"
	message_body_template    = "Triggered Alert : '[[metric-name]]' for interval [[alert-interval]] at [[time]][[time-zone]]\nTrigger value : [[trigger-opp]] [[trigger-value]]\nActual  value : = [[metric-value]]\n\n"

	ticket_subject_template = "Prometheus Alert - [[system-name]] [[[site-url]]] ([[system-tier]])  [[date]]"
	ticket_header_template  = "[[system-name]] [[system-tier]]\n\n"
	ticket_body_template    = "Triggered Alert : '[[metric-name]]'\nTrigger value : [[trigger-opp]] [[trigger-value]]\nActual  value : = [[metric-value]]\n\n"

	cnx = MySQLdb.connect(host=servername, user=username, passwd=password, db=dbname)
	cursor = cnx.cursor()
	query = "SELECT id as interval_id FROM intervals WHERE name = '" + str(interval) + "'"
	cursor.execute(query)
	results =cursor.fetchall()
	cursor.close()

	if len(results)==0:
		print "Unknown interval '" + str(interval) + "'"
		exit()

	interval_id = str( results[0][0] )

	print "----------"
	print "Running alerts with interval " + str(interval) + " at " + datetime.datetime.now().strftime("%y/%m/%d %H:%M")


	cnx = MySQLdb.connect(host=servername, user=username, passwd=password, db=dbname)
	cursor = cnx.cursor()
	query = "SELECT s.id as system_id, s.name AS system_name, s.url AS system_url, s.port AS system_port, t.name AS system_tier FROM systems s, alerts a, tiers t WHERE s.id = a.system_id AND s.tier_id = t.id AND a.status = 1 AND a.alert_interval = " + str(interval_id) + " GROUP BY s.id"
	cursor.execute(query)
	results =cursor.fetchall()
	cursor.close()

	print "Checking " + str( len(results)) + " systems"

	for ( result ) in results:
		
		system_id = result[0]
		system_name = result[1]
		system_url = result[2]
		system_port = result[3]
		system_tier = result[4]

		print"- - - - -"
		print system_id, system_name, system_url, system_port, system_tier

		alert_count = 0
		message_body = "[[site-url]]\n\n"
		ticket_body = ""

		cursor= cnx.cursor()
		query = "SELECT m.name AS metric_name, m.query AS metric_query, a.trigger_opp AS trigger_opp, a.trigger_value AS trigger_value FROM systems s, alerts a, metrics m, channels c, tiers t WHERE s.id = "+str(system_id)+" AND s.id = a.system_id AND a.metric_id = m.id AND a.channel_id = c.id AND s.tier_id = t.id AND a.status = 1 AND a.alert_interval = " + str(interval_id) + ""
		cursor.execute(query)

		print "Checking " + str(cursor.rowcount) + " alerts"
    
		for ( metric_name, metric_query, trigger_opp, trigger_value ) in cursor:

			print"-   -   -"

			metric_query = metric_query.replace('[[site-url]]', system_url )
			metric_query = metric_query.replace('[[site-port]]', str(system_port) )
			metric_query = metric_query.replace('[[metric-range]]', str(interval) )

			safe_metric_query = urllib.quote_plus( metric_query )
			#metric_url   = "http://sys-vsvr-promon:9090/api/v1/query?query=" + safe_metric_query
			metric_url   = "http://promon.imagencloud.com:9090/api/v1/query?query=" + safe_metric_query


			metric_raw = str( urllib.urlopen(metric_url).read() )
			metric_json = json.loads( metric_raw )

			if metric_json['status'] =="error":
				print "Prometheus query error : " +metric_json['error']
				print metric_url
				exit()

			metric_status = str( metric_json['data']['result'] )

			if metric_status == "[]" :
				metric_value = "0"
		
			elif metric_status != "[]" :
				metric_value = str( metric_json['data']['result'][0]['value'][1] )

			alert_triggered = 0

			if   trigger_opp == "=" and float(metric_value) == float(trigger_value):
				alert_triggered = 1
			elif trigger_opp == ">" and float(metric_value) > float(trigger_value):
				alert_triggered = 1
			elif trigger_opp == "<" and float(metric_value) < float(trigger_value):
				alert_triggered = 1
			elif trigger_opp == "!" and float(metric_value) != float(trigger_value):
				alert_triggered = 1

			#print system_name, system_url, system_port, system_tier, metric_name, safe_metric_query, metric_value, trigger_opp, trigger_value, alert_triggered
			print trigger_opp, trigger_value, alert_triggered, metric_name, safe_metric_query, metric_value

			if alert_triggered == 1:

				alert_count += 1

				alert_message = message_body_template.replace('[[system-name]]', system_name )
				alert_message = alert_message.replace('[[metric-name]]', metric_name )
				alert_message = alert_message.replace('[[system-tier]]', system_tier )
				alert_message = alert_message.replace('[[alert-interval]]', interval )
				alert_message = alert_message.replace('[[trigger-opp]]', trigger_opp )
				alert_message = alert_message.replace('[[trigger-value]]', str(trigger_value) )
				alert_message = alert_message.replace('[[metric-value]]', metric_value )
				alert_message = alert_message.replace('[[time]]', time.strftime('%H:%M') )
				alert_message = alert_message.replace('[[time-zone]]', time.tzname[time.localtime().tm_isdst] )

				message_body = message_body + alert_message
				ticket_body = ticket_body + alert_message

		cursor.close()

		if alert_count > 0 :

			message_subject = message_subject_template
			message_subject = message_subject.replace('[[system-name]]', system_name )
			message_subject = message_subject.replace('[[site-url]]', system_url )
			message_subject = message_subject.replace('[[system-tier]]', system_tier )
			message_subject = message_subject.replace('[[alert-count]]', str(alert_count) )
			message_subject = message_subject.replace('[[date]]', today.strftime('%d/%m/%Y') )

			message_body = message_subject + "\n\n" + message_body


			#print "_____________________________________________________"
			#print message_subject
			#print "_____________________________________________________"
			#print message_body
			#print "_____________________________________________________"
			#print


			# EMAIL

			send_email(ap_config, 'proalert-email@imagenltd.pagerduty.com', message_subject, message_body)
			#send_email(ap_config, 'jeff.powell@imagenevp.com', message_subject, message_body)
			#send_email(ap_config, '447515746381@bulksms.co.uk', message_subject, message_body)

			# POST to Zendesk

			ticket_subject = ticket_subject_template
			ticket_subject = ticket_subject.replace('[[system-name]]', system_name )
			ticket_subject = ticket_subject.replace('[[system-tier]]', system_tier )
			ticket_subject = ticket_subject.replace('[[alert-count]]', str(alert_count) )
			ticket_subject = ticket_subject.replace('[[[site-url]]]', '' )
			ticket_subject = ticket_subject.replace('[[date]]', today.strftime('%d/%m/%Y') )
	
			ticket_tag = ticket_subject.replace(' ', '' )
			ticket_tag = ticket_tag.replace('/', '' )
			ticket_tag = ticket_tag.replace('-', '' )
			ticket_tag = ticket_tag.replace('(', '' )
			ticket_tag = ticket_tag.replace(')', '' )


			z_search_credentials = "Prometheus@imagenevp.com","Prometheus"
			z_search_parameters = { 'query': 'tags:' + ticket_tag }

			z_search_session = requests.Session()
			z_search_session.auth = z_search_credentials

			z_search_url = "https://cambridgeimaging.zendesk.com/api/v2/search.json?" + urllib.urlencode(z_search_parameters)

			z_search_response = z_search_session.get(z_search_url)

			if int(z_search_response.status_code) != 200:
				print('Status:', z_search_response.status_code, 'Problem with the request. Exiting.')
				#exit()

			result_raw = z_search_response.json()
			
			zendesk_ticket_count = int( result_raw['count'] )

			if zendesk_ticket_count == 0:

				print "*****"
				print "Opening new ticket with alert details"

				zendesk_ticket_subject = ticket_subject

				post_url = 'https://cambridgeimaging.zendesk.com/api/v2/tickets.json'

				post_body = ticket_body
				post_data = { 'ticket': { 'status': 'new', 'type': 'incident', 'subject': zendesk_ticket_subject, 'tags': ticket_tag, 'comment': { 'body': post_body } } }
				post_payload = json.dumps(post_data)
				post_headers = headers = {'content-type': 'application/json'}
				post_credentials = "Prometheus@imagenevp.com","Prometheus"

				post_response = requests.post(post_url, data=post_payload, auth=( post_credentials ), headers=post_headers)

				print "1>" + str(int(post_response.status_code)) + "<1"

				if int(post_response.status_code) == 201:
					print 'Successfully created ticket'
				else:
					print 'Status:' + str( post_response.status_code ) + 'Problem with the request. Exiting.'
					print post_response
					print post_response.text
    				#exit()

				print "*****"

			elif zendesk_ticket_count == 1:

				zendesk_ticket_id = str( result_raw['results'][0]['id'] )

				print "*****"
				print "Appending alert details to ticket : " + str(zendesk_ticket_id)

				put_url = 'https://cambridgeimaging.zendesk.com/api/v2/tickets/' + zendesk_ticket_id + '.json'

				put_body = ticket_body
				put_data = { 'ticket': { 'status': 'open', 'type': 'problem', 'comment': { 'body': put_body } } }
				put_payload = json.dumps(put_data)
				put_headers = headers = {'content-type': 'application/json'}
				put_credentials = "Prometheus@imagenevp.com","Prometheus"

				put_response = requests.put(put_url, data=put_payload, auth=( put_credentials ), headers=put_headers)
				
				print "2>" + str(int(put_response.status_code)) + "<2"

				if int(put_response.status_code) == 200:
					print 'Successfully added alert details to ticket ' + str( format(zendesk_ticket_id))
				else:
					print 'Status:' + str( put_response.status_code ) + 'Problem with the request. Exiting.'
					print put_response
					print post_response.text
					#exit()

				print "*****"

	

	cnx.close()
	#send_email(ap_config, 'jeff.powell@imagenevp.com', "proc end", "")
	print "Done Running alerts with interval " + str(interval) + " at " + datetime.datetime.now().strftime("%y/%m/%d %H:%M")+ "\n\n\n"
	


### BEGIN MAIN PROCEDURE

import MySQLdb
import smtplib
import urllib
#from urllib.parse import urlencode
import json
import datetime
import requests
#from zenpy import Zenpy
import os
#import subprocess
import sys
import time

# Get interval from command argument
if len( sys.argv ) != 2:
	print "You must pass one alert interval as a parameter"
	exit()
alert_interval = sys.argv[1]

# Get DB connection details from config file
ap_config = read_config()

# Check all alerts configured to run at this time
check_systems(ap_config, alert_interval)

