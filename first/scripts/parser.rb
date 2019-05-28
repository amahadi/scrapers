require 'nokogiri'
require 'httparty'

def parser url
	url = url
	unparsed_page = HTTParty.get(url)
	parsed_page = Nokogiri::HTML(unparsed_page)
    return parsed_page
end
