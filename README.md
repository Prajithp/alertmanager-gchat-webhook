# alertmanager-gchat-webhook

## A simple Mojolicious::Lite webapp to push notifications from alertmanager to google chat. 
### It uses alertmanager webhook feature to receive messages and pushes the same to google chat after creating a nice dynamic card based on the labels configured in the config file.
  
## Installation 
### docker:
 ```
 $> docker build -t alertmanager-webook .
 $> docker run -d --name alertmanager-webook \
    -p 8080:8080 --restart=unless-stopped \
    -v $(pws)/alerts.yaml:/app/alerts.yaml alertmanager-webook:latest
 ```
 
 ### build manually:
  1. Make sure you have perl version >= 5.30 
