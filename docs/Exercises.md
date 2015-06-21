#Exercises

This document describes step by step how to complete each of the tutorial exercises.

##Setup

1) Start the VM

2) Open a web browser and check the demo app is working.

```
web.Logstashdemo.com
```

3) Open a new tab and check Kibana console is available

```
logs.Logstashdemo.com:5601
```

4) Open the supplied editor "Atom" and open:

```
/home/Logstashdemo
```

##Exercise One - Ingesting Nginx Access Logs

The aim of this exercise is to get us up and running with the ELK stack.

###Where are the logs?

Open an ssh terminal and tail the nginx access log of the demo app.

```
tail -f /var/log/nginx/helloapp.access.log
```

###How can we generate some log traffic?

Use curl to make requests to the demo app.

```
curl web.Logstashdemo.com
```

### Getting these logs into the ELK stack

In order to get this raw log data into we need to do two things:

1) Configure Logstash to accept log data, parse them and send them to elastic search.

2) Use the Logstash forwarder to tail the log file and send the logs to Logstash

####Configure Logstash

Logstash config is divided into three sections. Input, Filter and Output.

Lets create input and output config:

* sudo nano /etc/logstash/conf.d/input.conf

```
input {
  lumberjack {
    port => 5000
    type => "logs"
    ssl_certificate => "/etc/pki/tls/certs/logstash-forwarder.crt"
    ssl_key => "/etc/pki/tls/private/logstash-forwarder.key"
  }
}
```

* sudo nano /etc/logstash/conf.d/output.conf

```
output {
  elasticsearch { host => localhost }
}
```

Restart logstash.

```
sudo service logstash restart
```

####The Logstash Forwarder

1) Create a Logstash forwarder config file:

```
{
  "network": {
    "servers": [ "logs.logstashdemo.com:5000" ],
    "timeout": 15,
    "ssl ca": "/etc/pki/tls/certs/logstash-forwarder.crt"
  },
  "files": [
    {
      "paths": ["/var/log/nginx/helloapp.access.log"],
      "fields": { "type": "nginx-access" }
    }
  ]
}
```

2) Run the Logstash forwarder with the newly created config file.

```
sudo logstash-forwarder --config /path/to/config
```

####Verifying End To End System

1) Generate some log traffic.

2) Check the Kibana logstash dashboard for log entries

## Exercise Two: Parsing log data

Currently the log data exists in a very raw form in Elasticsearch. This makes it difficult to search for specific log entries in Kibana.

Logstash can further parse incoming log entries before sending them to logstash to make it easier to search via Kibana.

###Adding A Grok Filter

Create a filter config for logstash:

* sudo nano /etc/logstash/conf.d/filter.conf

```
filter {
  if [type] == "nginx-access" {
    grok {
     match => { "message" => "%{COMBINEDAPACHELOG}" }
     add_field => [ "received_at", "%{@timestamp}" ]
     add_field => [ "received_from", "%{host}" ]
    }
  }
}
```

###Testing the new filter

1) Restart logstash

```
sudo service logstash restart
```

2) Generate some traffic

3) Access the kibana logstash dashboard. Notice new log entries have top level fields.

##Exercise Three: Searching log data in kibana

After logs have been ingested via logstash into elasticsearch  they can be searched via
kibana.

In order to demonstrate searching we need some more varied web log data.
Generate some traffic to the /flappy end point which produces a wide range
of http responses.

```
curl web.logstashdemo.com/flappy
```

###Kibana dashboard - Basic Search

![Searh Histogram](https://www.evernote.com/shard/s558/sh/82ba540f-bd0f-4756-bb80-5b62efc4dab0/a1c48ce2721d17980a8f22379df87305/deep/0/Screen-Shot-2015-06-21-at-16.39.03.png)


![Results-1](https://www.evernote.com/shard/s558/sh/6c72a95e-f3c0-46c7-a53a-6bcd48afd166/2bd444441737426f0724b0e5a8ea04d8/deep/0/Screen-Shot-2015-06-21-at-16.39.24.png)


![Results-2](https://www.evernote.com/shard/s558/sh/84f4c7ea-407d-4f12-bd2f-9b1f0e7a8a3b/5227bccdfc128d69e1a4105f40e0348f/deep/0/Screen-Shot-2015-06-21-at-16.40.06.png)

###Time Filtering

The time filter is used to select when log entries should be displayed.

eg - Last 5 min, Last 15 min


###Queries

Any field which has been 'Groked' can be searched on using the query bar.

Here are some example searches:

* 404 responses

```
response:404
```

* 404 responses for the /flappy endpoint

```
response:404 AND request: /flappy
```

* Error Responses

```
response: >=500
```

##Exercise Four: Ingesting Historical Data

You may want to ingest historical log data into elasticsearch for analysis.
We can also use this as a demonstration of the important "date" parameter
in the logstash "format" configuration.

###Delete previous log data

**If still running: stop the logstash forwarder used in the previous example**

1) Go to:

```
http://elastic.logstashdemo.com/_plugin/HQ/
```

2) Click "Connect"

3) In the "Indices" section click the index with todays date

4) Click "Administration"

5) Click "Delete Index" and confirm

6) Go to Kibana, note: there is no longer any log data

###Update the logstash config to allow historical ingestion

Add stdin as an input type.

* sudo nano /etc/logstash/conf.d/input.conf

```
input {
  lumberjack {
    port => 5000
    type => "logs"
    ssl_certificate => "/etc/pki/tls/certs/logstash-forwarder.crt"
    ssl_key => "/etc/pki/tls/private/logstash-forwarder.key"
  }
  stdin { type => "nginx-access"  }
}
```

Add stdout as an output type.

* sudo nano /etc/logstash/conf.d/output.conf

```
output {
  elasticsearch { host => localhost }
  stdout { codec => rubydebug }
}
```

###Ingest historical log data

Cat the previously collected access logs into the logstash process

```
sudo cat /var/log/nginx/helloapp.access.log | /opt/logstash/bin/logstash --config=/etc/logstash/conf.d
```

Note: you can also use the "file" input type to achieve the same result

You should see the log data being ingested into elastic search

Go to kibana and check the log data arrived.

The log data is present however notice that the time the log data is reported to
have occured is incorrect!

###Ingesting historical log data - with the correct date

Logstash is able to use one of the groked fields as the timestamp used when searching
and filtering data. To do this add a date filter to the filter config.

* sudo nano /etc/logstash/conf.d/filter.conf

```
filter {
  if [type] == "nginx-access" {
    grok {
     match => { "message" => "%{COMBINEDAPACHELOG}" }
     add_field => [ "received_at", "%{@timestamp}" ]
     add_field => [ "received_from", "%{host}" ]
    }
    date {
      match => [ "timestamp", "dd/MMM/yyyy:HH:mm:ss Z"]
    }
  }
}
```

##Exersise Five - Custom Groks

"Groking" is one of the most important concepts when parsing unstructured data
with logstash.

1) In the directory */home/vagrant/misc* there is a sample log file using a custom log format

2) Write a single config file (with input / output / filter sections) that you
can use to ingest the data into logstash.

3) Parse the data into logstash using the command

```
sudo cat /home/vagrant/misc/log.log | /opt/logstash/bin/logstash --config=/home/vagrant/newconfig.conf
```

Hints:

* Use a new "type" to allow for easy searching of the log entries
* Remember to use the date filter to ensure the logs are imported correctly
* If parsing a log fails it's parsed with \_grokparsefailure
* Use the two links below to help you construct the grok

```
http://grokdebug.herokuapp.com/
https://github.com/elasticsearch/logstash/blob/v1.4.2/patterns/grok-patterns
```

### Adding response time to Nginx Logs

It would be useful if we could add some information about response time into
the nginx access logs. Using a custom grok We can later visualise this 'non standard' nginx access data in Kibana and use it
to analyse site performance.

1) Declare a new log format in the the nginx config file.

* sudo nano /etc/nginx/nginx.conf

```
http {

... more config here ...

log_format timed_combined '$remote_addr - $remote_user [$time_local] '
    '"$request" $status $body_bytes_sent '
    '"$http_referer" "$http_user_agent" '
    '$request_time $upstream_response_time';  

```

2) Configure the nginx vhost serving the demo application to use the new format

* sudo nano /etc/nginx/sites-available/logdemo.conf

```
server {

  ... More config here ...

      access_log /var/log/nginx/helloapp.access.log timed_combined;
```

3) Restart nginx

```
sudo service nginx restart
```

4) Generate some web traffic

5) Note in Kibana new log data now has the tag '\_grokparsefailure'

6) Update the logstash filter config to grok the new log pattern. Add the fields
"request_time" and "upstream_request_time".

7) Restart logstash

8) Generate some more web traffic

9) Note in Kibana that access logs are being groked correctly now and the new
fields are available.

### Adding Varnish Request ID to log data

Varnish drops a unique ID into the http headers of the requests its forwards to
nginx. By including this in the access logs and tagging application logs with
the same varnish id its possible to tie logs from a range of logs to a single user
request.

1) Edit the previously declared log format in the the nginx config file. Adding
the http header to the end of the log.

* sudo nano /etc/nginx/nginx.conf

```
http {

... more config here ...

log_format timed_combined '$remote_addr - $remote_user [$time_local] '
    '"$request" $status $body_bytes_sent '
    '"$http_referer" "$http_user_agent" '
    '$request_time $upstream_response_time $http_x_varnish';  

```

2) Restart nginx

3) Adjust the grok in the logstash filter config. Add the field "varnish_id".

4) Restart logstash

5) Generate some web traffic

6) Note in Kibana the access logs have a new field "varnish_id"

7) Request the demo app from a web browser, note the varnish_id in the header.
This is now searchable in Kibana.

###Updating Kibana index mappings

For the new fields to be searchable Kibana must update it's index mappings.

1) Go to "Settings"

2) Click the orange "Reload Field List" button


##Exercise Six - Logstash And PHP

We can use logstash to capture our PHP application logs.

In this exercise we configure an instance of monolog and send the logs produced
to logstash and elastic search for use later.

###Configuring Monolog

- See demo

###Configuring Logstash

1) Add the file to the logstash-forwarder config as in the previous example.
  - Remember to use a new type to allow logstash to distinguish between the different
  types of logs being forwarded.

2) Create a new section in the filter block

```
filter {
  if [type] == "helloapp-applog" {
    json {
     source => "message"
     add_field => [ "received_at", "%{@timestamp}" ]
     add_field => [ "received_from", "%{host}" ]
    }
  }
}
```

Note the use of the JSON filter. Monolog serializes the log data to JSON.

##Exercise Seven Visualisation / Dashboard Creation

The aim of this exercise is to create a several visualisations of the data
we have gathered. These visualisations can then be grouped into dashboards.

![Dashboard](https://www.evernote.com/shard/s558/sh/5abba168-7e8c-49a2-9fae-8436eb15a292/5a35e1eee6574746984a86c091f2069d/deep/0/Screen-Shot-2015-06-21-at-16.37.59.png)

![Wireframe](https://www.evernote.com/shard/s558/sh/dd8a9e9b-cf34-424e-8f05-ddd146689b7b/d8d950740f08124e5cc5d49e411b2c33/deep/0/Blank-Flowchart---New-Page.png)

1) Create a visualisation for each of the blocks on the wireframe.

2) Create a dashboard by using each of these visualisations.
