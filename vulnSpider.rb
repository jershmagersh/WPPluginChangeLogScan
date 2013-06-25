#!/usr/bin/ruby
require 'net/http'
require 'uri'

@log_file = File.new("log.txt", "w")

def start
	puts "Would you like to search for plugins?"
	answer = gets.chomp
	getTags if answer.upcase == "Y"
end

def grabPlugins(tag)
	uri = URI('http://wordpress.org/plugins/tags/' + tag)
	resp = Net::HTTP.get_response(uri)
	
	arrPageNums = resp.body.scan(/dots.*\/span><a class="page-numbers" href="\/plugins\/tags\/widget\/page\/(.*?)"/)
	
	puts "Grabbing links..."
	for i in 1..arrPageNums[0][0].to_i
		uri = URI('http://wordpress.org/plugins/tags/' + tag + '/page/' + i.to_s)
		resp = Net::HTTP.get_response(uri)
		arrPlugins = resp.body.scan(/<h3><a href="http:\/\/wordpress.org\/plugins\/(.*?)\/">(.*?)<\/a><\/h3>/)
		
		for i in 0..arrPlugins.length-1
			spiderPlugin(arrPlugins[i][1], arrPlugins[i][0])
		end
	end
end

def spiderPlugin(pluginName, uri)
	uri = URI("http://wordpress.org/plugins/" + uri + "/changelog/")
	
	resp = Net::HTTP.get_response(uri)
	
	arrChangeLogData = resp.body.scan(/<h4>(.*?)<\/h4>.*?<li>(.*?)<\/li>/m)
	
	readChangeLog(arrChangeLogData, pluginName, uri)
end

def readChangeLog(arrData, pluginName, uri)
	for i in 0..arrData.length-1
		version = arrData[i][0]
		log = arrData[i][1]
		
		if(checkForSec(log))
			@log_file.puts "\nPlugin: #{pluginName}\nURI: #{uri}\nVersion: #{version}\nLog: #{log}"
			puts "\nPlugin: #{pluginName}\nURI: #{uri}\nVersion: #{version}\nLog: #{log}"
		end
	end
end

def getTags
	puts "Getting most popular tags..."
	
	uri = URI('http://wordpress.org/plugins/tags/')
	resp = Net::HTTP.get_response(uri)
	
	scanned = resp.body.scan(/\/tags\/(.*)'.*title.*style='font-size:(.*)pt;'>/)
	
	scanned = scanned.sort{|a, b| a[1].to_f <=> b[1].to_f}

	puts "Starting with the most popular: #{scanned[scanned.length-1][0]}"
	
	grabPlugins(scanned[scanned.length-1][0])
	
	puts "Keep going?"
	answer = gets.chomp
	
	if answer.chomp.upcase == "Y"
		for i in 2..scanned.length-1 
			grabPlugins(scanned[scanned.length-i][0])
		end
	end
end

def checkForSec(log)
	arr = log.scan(/XSS|Cross[\-\s]Site Scripting|XSRF|CSRF|SQL Injection|Cross[\-\s]Site Request Forgery|Security/i)
	if(arr.length > 0)
		return true
	else
		return false
	end
end

start
