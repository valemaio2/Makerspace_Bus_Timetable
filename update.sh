#!/bin/bash
cd /home/hackspace/buses-api

bin/python train_fetch.py config.json data/
bin/python sync.py config.json
bin/python generate.py config.json
