#!/usr/bin/env ruby
# encoding: UTF-8
#Freifunk node highscore game
#Copyright (C) 2012 Anton Pirogov
#Licensed under The GPLv3

#--------
#Settings
#--------

TITLE = "Freifunk Troisdorf Node Highscores"
GRAPHLINK='http://map.freifunk-troisdorf.de'

#source path of node data
JSONSRC='/srv/ffmap-d3/build/nodes.json'

#password for commands over GET requests
PWD='LVcVz6uV6WsyEnJLBF0MLUfwW'

#score values
SC_OFFLINE=-100
SC_GATEWAY=100
SC_PERCLIENT=25
SC_PERVPN=10 #divided by quality
SC_PERMESH=50 #divided by quality

#----

#hide following nodes from scores
BLACKLIST=['SRV:wupper0','SRV:wupper1','SRV:map','SRV:dns','gateway1','SRV:update1']

#----

#enable logging
LOG=true
LOG_FILE='log.txt'
