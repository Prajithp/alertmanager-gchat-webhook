# alertmanager-gchat-webhook
 A simple Mojolicious::Lite webapp to push notifications from alertmanager to google chat. It uses alertmanager webhook feature to receive messages and pushes the same to google chat after creating a nice dynamic card based on the labels configured in the config file.
  
## Installation 
### docker:
 ```
 $> docker build -t alertmanager-webook .
 $> docker run -d --name alertmanager-webook \
    -p 8080:8080 --restart=unless-stopped \
    -v $(pwd)/alerts.yaml:/app/alerts.yaml alertmanager-webook:latest
 ```
 
### Install manually:
Make sure you have perl version >= 5.30.
```
cpanm --installdeps .
```
start the application with hypnotoad
```
hypnotoad alertmanager.pl
```

### AlertManager Configuration - Example
```
global:
  resolve_timeout: 5m

route:
  group_by: ['alertname']
  group_wait: 10s
  group_interval: 10s                                                                                                                                                                          
  repeat_interval: 1m                                                                                                                                                                          
  receiver: 'googleChat'                                                                                                                                                                       
receivers:                                                                                                                                                                                     
- name: 'googleChat'                                                                                                                                                                           
  webhook_configs:
  - url: 'http://127.0.0.1:8080/notify?channel=devops'

inhibit_rules:
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname', 'dev', 'instance']

```


