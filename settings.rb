#!/usr/bin/env ruby
# encoding: UTF-8
#Freifunk node highscore game
#Copyright (C) 2012 Anton Pirogov
#Licensed under The GPLv3

#--------
#Settings
#--------

#source path of node data
JSONSRC='/home/zenforyen/public_html/nodes.json'

#password for commands over GET requests
PWD='hackme'

#score values
SC_OFFLINE=-100
SC_GATEWAY=100
SC_PERCLIENT=25
SC_PERVPN=10 #divided by quality
SC_PERMESH=50 #divided by quality

#----

#hide following nodes from scores
BLACKLIST=['burgtor','holstentor','muehlentor','huextertor']

#----

#enable logging
LOG=true
