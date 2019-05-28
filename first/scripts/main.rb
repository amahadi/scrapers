load "scripts/scraper_and_saver.rb"

puts "Enter Repository url: "
repo_url = gets



scraper_and_saver repo_url.strip
