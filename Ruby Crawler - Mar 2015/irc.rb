#!/usr/bin/env ruby
require 'cinch'
require 'pry'

bot = Cinch::Bot.new do
  configure do |c|
    c.server = "irc.freenode.org"
    c.nick = "tcw-echo-bot"
    c.channels = ["#thecodewarrior-bots ruby-bots"]
  end

  on :message, /\.echo (.+)/ do |m, match|
    m.reply match
  end
end

bot.start