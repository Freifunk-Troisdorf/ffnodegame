#!/usr/bin/env ruby
#Freifunk node highscore game
#Copyright (C) 2012 Anton Pirogov
#Licensed under The GPLv3

require 'json'
require 'open-uri'

require './settings'

#write line to log if log enabled
def log(txt)
  `echo "#{Time.now.to_s}: #{txt}" >> #{LOG_FILE}` if LOG
end

class Scores

  @@scorepath = 'public/scores.json'

  #--------

  #return last update time -> last modification to file
  def self.last_update
    return File.mtime @@scorepath
  rescue
    return Time.new(0)
  end

  #take score file and generate a sorted highscore list of requested span for output
  def self.generate(days=1, offset=0)
    scores = read_scores

    #sum up requested day scores
    scores.each{|e| e['points'] = e['points'][offset,days].to_a.inject(&:+).to_i}

    #return without losers
    scores.delete_if{|e| e['points']<=0}

    #sort by score
    scores.sort_by! {|e| e['points']}.reverse!

    return scores
  end

  def self.reset
    File.delete @@scorepath
    return true
  rescue
    return false
  end

  #run one update cycle and generate/update the score file
  def self.update
    scores = read_scores

    #load node data
    jsonstr = nil
    begin
      jsonstr = open(JSONSRC,'r:UTF-8').read
    rescue
      return false #failed!
    end

    #NOTE: filtering and analyzing of JSON data fits perfectly here
    data = JSON.parse jsonstr
    snapshot = transform data
    merge scores, snapshot

    scorejson = JSON.generate scores
    File.write @@scorepath, scorejson
    return true
  end

  private

  #load current score file or fall back to empty array
  def self.read_scores
    return JSON.parse open(@@scorepath,'r:UTF-8').read
  rescue
    return []
  end

  #insert fresh new day score entry
  def self.rotate(scores)
    scores.each do |e|
      e['points'].unshift 0
      e['points'].pop if e['points'].length > 30
    end
  end

  #clean and prepare node data
  def self.transform(nodejson)
    nodes = nodejson['nodes']
    links = nodejson['links']

    nodes.each do |n|
      n['meshs']=[]
      n['vpns']=[]
      n['clients']=n['clientcount']
      n.delete 'clientcount' #copied to clients
      n.delete 'geo'  #not interesting
      n.delete 'id' #not interesting
    end

    links.each do |l|
      t = l['type']
      src = l['source']
      dst = l['target']

      if t.nil? #meshing
        quality=l['quality'].split(", ").map(&:to_f)
        nodes[src]['meshs'] << quality[0]
        nodes[dst]['meshs'] << quality[1] if quality.size>1
      elsif t=='vpn'
        quality=l['quality'].split(", ").map(&:to_f)
        nodes[src]['vpns'] << quality[0]
        nodes[dst]['vpns'] << quality[1] if quality.size>1
      end
    end

    #now can delete nodes (before order mattered)
    nodes.delete_if{|n| n['name'].empty?}
    nodes.delete_if{|n| BLACKLIST.index n['name']}

    return nodes
  end

  #calculate and add points for node in current round and set info for html
  def self.calc_points(node)
    #reset current status data
    node['sc_offline'] = node['sc_gateway'] = node['sc_clients'] = 0
    node['sc_vpns'] = node['sc_meshs'] = 0
    node['points'] = [0] if node['points'].nil?
    p = node['points']

    if !node['flags']['online']  #offline penalty
      p[0] += (node['sc_offline'] = SC_OFFLINE)
      return
    end

    p[0] += ( node['sc_gateway'] = SC_GATEWAY ) if node['flags']['gateway']

    p[0] += ( node['sc_clients'] = SC_PERCLIENT * node['clients'] )

    p[0] += ( node['sc_vpns'] = node['vpns'].map{|e| SC_PERVPN / e}.inject(&:+).to_i )
    p[0] += ( node['sc_meshs'] = node['meshs'].map{|e| SC_PERMESH / e}.inject(&:+).to_i )
  end

  #update scores, add new nodes, remove old nodes with <=0 points
  def self.merge(scores, data)
    #start new day points field on day change between updates
    rotate scores if last_update.day < Time.now.day

    #garbage collection:
    #detect nodes which are gone from source data (by name so node renames affected too)
    #and let them slowly die (by offline penalty)
    scores.select{|s| !data.index{|d| d['name']==s['name']}}.each do |s|
      s['flags']['online']=false
      s['flags']['gateway']=false
      s['vpns'] = []
      s['meshs'] = []
      s['clients'] = 0
      calc_points s
    end

    #To prevent multiple nodes with same name mixed up take only first
    seen = Hash.new false

    #perform regular update
    data.each do |n|
      next if seen[n['name']]
      seen[n['name']] = true

      i = scores.index{|s| s['name'] == n['name'] }
      if i.nil? #new entry
        scores.push n
        calc_points scores[-1]
      elsif #update preserving points array
        p = scores[i]['points']
        scores[i] = n
        scores[i]['points'] = p
        calc_points scores[i]
      end
    end

    return scores
  end
end
