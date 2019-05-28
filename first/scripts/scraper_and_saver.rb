load 'scripts/parser.rb'
require 'byebug'
require 'set'
require 'csv'
require 'colorize'

def scraper_and_saver repo_url
	initial_url = "#{repo_url.strip}/pulls?page=1&q=is%3Apr+is%3Aclosed"
	repo_page = parser repo_url.strip
	parsed_page = parser initial_url
	parsed_page.css("div.pagination").css("a").last.remove
	total_pages = parsed_page.css("div.pagination").css("a").last.children.text.to_i
	next_page_number = 1
	next_page_url = "#{repo_url.strip}/pulls?page=#{next_page_number}&q=is%3Apr+is%3Aclosed"
	file_name = repo_page&.css("div.repohead-details-container.clearfix.container")&.css("h1")&.css("a")&.children&.last&.text
	CSV.open("datasets/#{file_name}.csv", "a") do |csv|
	 	csv << ["number", "comment", "type"]
	end 	
	puts "Parsing data from #{next_page_url}".yellow
	CSV.open("datasets/#{file_name}.csv", "a") do |csv|
		while next_page_url <= total_pages do
			parsed_page = parser next_page_url
			pull_requests = parsed_page.css("div.d-table.table-fixed.width-full.Box-row--drag-hide.position-relative")
			pull_requests.each do |pull_request|
				pull_request_url = "https://github.com#{pull_request.css("div.float-left.col-9.lh-condensed.p-2").css("a")&.first&.values&.last}"
				pull_request_page = parser pull_request_url
				pull_request_number = pull_request_page.css("span.gh-header-number").text
				all_comments = [" "]
				main_comments = pull_request_page&.css("div.timeline-comment-group.js-minimizable-comment-group.js-targetable-comment")&.css("td.d-block.comment-body.markdown-body.js-comment-body")&.children
				main_comments.each do |main_comment|
					unless main_comment.text.strip == ""
						if main_comment.text[0] == "\n"
							main_comment = main_comment.text.strip.gsub("\n", "")
							all_comments[all_comments.length - 1] = "#{all_comments[all_comments.length - 1]} #{main_comment.strip}" 	
						else
							all_comments << main_comment.text.strip	
						end
					end		
				end
				sub_comments = pull_request_page&.css("div.Box.review-summary.mt-3.mb-4")&.css("div.Box-body.comment-body.markdown-body.js-comment-body")&.children
				sub_comments.each do |sub_comment|
					unless sub_comment.text.strip == ""
						if sub_comment.text[0] == "\n"
							sub_comment = sub_comment.text.strip.gsub("\n", "")
							all_comments[all_comments.length - 1] = "#{all_comments[all_comments.length - 1]} #{sub_comment.strip}" 	
						else
							all_comments << sub_comment.text.strip	
						end
					end	
				end
				nested_comments = pull_request_page&.css("div.review-comment-contents.js-suggested-changes-contents")&.css("div.comment-body.markdown-body.js-comment-body")&.children
				nested_comments.each do |nested_comment|
					unless nested_comment.text.strip == ""
						if nested_comment.text[0] == "\n"
							nested_comment = nested_comment.text.gsub("\n", "")
							all_comments[all_comments.length - 1] = "#{all_comments[all_comments.length - 1]} #{nested_comment.strip}" 	
						else
							all_comments << nested_comment.text.strip	
						end
					end	
				end
				all_comments.to_set.each do |comment|
					unless comment.strip == ""
						csv << ["#{pull_request_number}", "#{comment}", "0"]
					end
				end
			end
			next_page_number += 1
			next_page_url = "#{repo_url.strip}/pulls?page=#{next_page_number}&q=is%3Apr+is%3Aclosed"
			puts "Parsing data from #{next_page_url}".yellow 
		end
	end
	puts "Comments parsed from #{repo_url} and saved in datasets/#{file_name}.csv".blue
	puts "Action performed successfully".green
end