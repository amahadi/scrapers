load 'scripts/parser.rb'
require 'byebug'
require 'set'
require 'csv'
require 'colorize'

def scraper_and_saver params
	pr_url = params[:pr_url]
	data_dir = params[:project_dir]
	puts "Parsing data from #{pr_url}...".yellow
	parsed_page = parser pr_url
	# repo_name = parsed_page&.css("div.repohead-details-container.clearfix.container")&.css("h1")&.css("a")&.children&.last&.text
	# file_name = "#{repo_name}_#{pr_url.tr("^0-9", '')}"
	CSV.open("#{data_dir}/comments.csv", "a") do |csv|
		pull_request_page = parsed_page
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
				csv << ["#{comment}"]
			end
		end
	end
	# puts "Comments parsed from #{pr_url} and saved in #{data_dir}/#{file_name}.csv".green
	puts "Done.".green
end