#!/usr/bin/python
# -*- coding: utf-8 -*-
import paho.mqtt.client as mqtt
from threading import Thread
import time
import json
import sys


index = 0

######## Data ########
gpsCoordinates = [
    {"lat": 33.000605,"lng": -96.767693},
    {"lat": 33.000012,"lng": -96.767629},
    {"lat": 32.998880,"lng": -96.766502},
    {"lat": 32.997938,"lng": -96.762744},
    {"lat": 32.997459,"lng": -96.760533},
    {"lat": 32.995821,"lng": -96.756185},
    {"lat": 32.995821,"lng": -96.756185},
    {"lat": 32.995821,"lng": -96.756185},
    {"lat": 32.995821,"lng": -96.756185},
    {"lat": 32.995821,"lng": -96.756185},
    {"lat": 32.995821,"lng": -96.756185},
    {"lat": 32.993240,"lng": -96.756461},
    {"lat": 32.992947,"lng": -96.754159},
    {"lat": 32.993225,"lng": -96.749553},
    {"lat": "null","lng":"null"}
];


mqttc = mqtt.Client("testMockData")
# mqttc.username_pw_set(username="stage_services",password="GrMLiT9KnCp0")
# mqttc.connect('mqtt.kuvi.io', port=1883, keepalive=60)
mqttc.connect('broker.emqx.io', port=1883, keepalive=60)
mqttc.loop_start()
while True:
    print(index)
    if index > len(gpsCoordinates)-1:
        mqttc.publish("test/matta/318c2f44-5d97-449e-8aef-416757103f10", "", qos=1,retain=True)
        exit()

    else:
        publishTime = int(round(time.time() * 1000))
        gpsCoordinates[index]["publishTime"] = publishTime;
        msg = gpsCoordinates[index]
        msg["publishTime"] = int(round(time.time() * 1000))
        pubMessage = json.dumps(msg)
        #publishTime = int(round(time.time() * 1000))
        print(pubMessage)
        mqttc.publish("test/matta/318c2f44-5d97-449e-8aef-416757103f10", payload=json.dumps(pubMessage), qos=1,retain=True)
        index = index + 1


    time.sleep(5)# sleep for 10 seconds before next call






#
