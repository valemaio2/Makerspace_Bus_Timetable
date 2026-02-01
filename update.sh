#!/bin/bash
cd ~/NextBus-GB-API-Python-parser

venv/bin/python train_fetch.py config.json data/
venv/bin/python sync.py config.json
venv/bin/python generate.py config.json
