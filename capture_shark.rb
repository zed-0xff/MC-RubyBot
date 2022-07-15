#!/usr/bin/env ruby
# frozen_string_literal: true
require 'json'
require 'open-uri'
require 'pp'

loop do
  data = URI.open("http://localhost:9999").read
  j = JSON.parse(data)
  if (entity = j['player']['looking_at']['entity']) && entity['id'] == 'minecraft:player' && entity['name'] != 'Nurse Shark'
    pp entity
    break
  end
  sleep 0.01
end
