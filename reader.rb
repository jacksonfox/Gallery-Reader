require 'rubygems'
require 'sinatra'
require 'feed-normalizer'
require 'open-uri'
require 'hpricot'
require 'rexml/Document'

RSS_FEEDS = ["http://feeds.feedburner.com/ffffound/everyone","http://feeds2.feedburner.com/picocool","http://konigi.com/feeds/konigi.rss","http://feedproxy.google.com/Notforpaper-TheBestDesignWorkForTheScreen"]

helpers do
	def parse_opml(opml_node, parent_names=[])
		feeds = {}
	  	opml_node.elements.each('outline') do |el|
			if (el.elements.size != 0) 
		  		feeds.merge!(parse_opml(el, parent_names + [el.attributes['text']]))
			end
			if (el.attributes['xmlUrl'])
		    	feeds[el.attributes['xmlUrl']] = parent_names
			end
		end
		return feeds
	end
	def image_src(html)
		h = Hpricot(html)
		src = ""
		unless h.search("img").empty?
	 		src = h.at("img")["src"]
		else
			src = ""
		end
		if src.include? "doubleclick" or src.include? "feedburner" or src.include? "wists"
			""
		else
			src
		end
	end
	def feeder_inline
		feed_items = []
		RSS_FEEDS.each do |feed|
			rss = FeedNormalizer::FeedNormalizer.parse open(feed)
			rss.items.each do |i|
 				src = image_src(i.description)
				feed_items.push({:feed => rss.title, :feedurl => rss.url, :title => i.title, :url => i.url, :src => src, :date => i.date_published})
			end
		end
		feed_items.sort! { |a,b| b[:date] <=> a[:date] }
		feed_items
	end
	def feeder_opml
		feed_items = []
		opml = REXML::Document.new(File.read('/Users/jackson/Dropbox/Projects/gallery-reader/feeds.xml'))
		feeds = parse_opml(opml.elements['opml/body'])
		feeds.each do |feed,tags|
			begin
				rss = FeedNormalizer::FeedNormalizer.parse open(feed)
				rss.items.each do |i|
	 				src = image_src(i.description)
					feed_items.push({:feed => rss.title, :feedurl => rss.url, :title => i.title, :url => i.url, :src => src, :date => i.date_published})
				end
			rescue NoMethodError => file_name
			end
		end
		feed_items.sort! { |a,b| b[:date] <=> a[:date] }
		feed_items
	end
end

get '/' do
	@stories = feeder_opml
	erb :index
end

get '/debug' do 
	@stories = feeder_inline
	erb :debug
end
