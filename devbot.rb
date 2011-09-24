require 'rubygems'
require 'bundler/setup'

require 'cinch'
require './cinch_better_plugin'

module Cinch
class IRC
	alias old_parse parse
	def parse(input)
		events = old_parse(input)
		msg = Message.new(input, @bot)

		events.each do |event, *args|
			@bot.dispatch_to_plugins(event, msg, *args)
		end
		if msg.message =~ /#{@bot.nick}/
			msg.instance_variable_set(:@events, [:mention])
			@bot.handlers.dispatch(:mention, msg, [])
			@bot.dispatch_to_plugins(:mention, msg, [])
		end
	end
end
end #module Cinch

@bot = Cinch::BetterBot.new do
	configure do |c|
		c.nick = "devbot"
		c.port = 6660
		c.server = "irc.xs4all.nl"
		c.channels = ["#gtammo.test"]
	end

	on :mention, /hello/ do |m|
		m.reply "Hello, #{m.user.nick}"
	end

	on :mention, /reload/ do |m|
		m.reply("You're not the boss of me!") and next if not m.channel.opped? m.user
		m.reply "Reloading plugins.."
		begin
			m.reply "Succesfully reloaded modules!"
			Dir[File.dirname(__FILE__) + '/modules/*.rb'].each do |plugin|
				load plugin
			end
		rescue LoadError
			m.reply "Sorry, I couldn't reload, #{m.user.nick} :("
		end
	end

	on :loaded_module do
	end
end

@bot.start
