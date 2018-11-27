require 'sinatra'
require 'date'
require 'socket'
require 'net/http'
require 'json'
require 'uri'

# Command 1
# /goldstar @erin.kross
#
# # add a star to erin
# # show the star total for erin
# GROOVY! @erin.kross has :star2: stars!
#
# Command 2
# /star
#
# #show the top 4 star leaderboard
#
# 1. @erin.kross 1,354,235 :star2:
# 2. @mike.prosper 1 :star2:

number_of_stars = 0
awkward_affirmation = [ "Marvelous!",
                        "Romantic?",
                        "Amazing!",
                        "Whaaaaaat?!",
                        "Sweetness.",
                        "Shame!",
                        "Stunning!",
                        "Fantastic!",
                        "Wonderfully done.",
                        "Terrific!",
                        "Brilliant!",
                        "Yoooooo!",
                        "YATAAAAA!",
                        "Sweeeet!",
                        "Huzzah!",
                        "Genius!",
                        "Creepy...",
                        "Yasssssss?",
                        "Duuude.",
                        "Excellent!",
                        "Awesome!",
                        "Fascinating!",
                        "Spectacular!",
                        "Remarkable!",
                        "Astonishing!",
                        "How?!" ]

get '/' do
  'This is the home page'
end


post '/goldstar' do

  # load an existing star file but only if it exists
  if File.exist?('stars.txt')
    #load file
    file = File.open('stars.txt', "r")
    # UNSAFELY convert the string to a hash
    star_hash = eval(file.read)
  else
    #start a new hash
    star_hash = { }
  end

  data = request.body

   if data != ""

     # Get URLencoded line
     slack_url = params["response_url"] #split_data.last.split("=").last
     unencoded_slack_url = URI.unescape(slack_url)

     #figure out who the user is and store it in a variable
     gold_star_user = params["text"] #split_data[8].split("=").last
     unencoded_gold_star_user = URI.unescape(gold_star_user)

     #figure out who the user running the command is and store it in a variable
     current_user = "@#{params["user_name"]}" #split_data[6].split("=").last

     puts "current_user: #{current_user}"
     puts "gold_star_user: #{unencoded_gold_star_user}"


      uri = URI(unencoded_slack_url)
      header = {'Content-Type': 'application/json'}
      response_text = ''

      puts "what is gold star? #{gold_star_user}"

      #if the gold_star_user is blank, show the leaderboard
      if gold_star_user == ''

        sorted_gold_star_users = star_hash.sort_by { |user, stars| -stars }
        sorted_limited_gold_star_users = sorted_gold_star_users.first(10)

        sorted_limited_gold_star_users.each do |single_gold_star_user|
          response_text += "<#{single_gold_star_user[0]}> has #{single_gold_star_user[1]} :star2:!\n"
        end

      elsif current_user == unencoded_gold_star_user

        response_text = "SHAME SHAME SHAME. <#{current_user}> tried to give themselves a star: https://media.giphy.com/media/Ob7p7lDT99cd2/giphy.gif"

      else

        number_of_stars = number_of_stars + 1

        #add the user to the hash and save the number of stars\
        if star_hash.has_key?(unencoded_gold_star_user)
          star_hash[unencoded_gold_star_user] += 1
        else
          star_hash[unencoded_gold_star_user] = 1
        end

        puts star_hash

        # write a file containing the hash so that stars can be saved across
        # application restarts
        open('stars.txt', 'w') { |f|
          f.puts star_hash
        }

        response_text = "#{awkward_affirmation.sample} <#{current_user}> gave <#{unencoded_gold_star_user}> a star! <#{unencoded_gold_star_user}> has #{star_hash[unencoded_gold_star_user]} :star2:!"

      end

      body = {
        "response_type": "in_channel",
        "text": response_text
      }

      Net::HTTP.start(uri.host, uri.port,
        :use_ssl => uri.scheme == 'https') do |http|
        request = Net::HTTP::Post.new(uri, header)
        request.body = body.to_json

        response = http.request request # Net::HTTPResponse object
        puts "message: #{response.message}"
        puts "code: #{response.code}"
        puts "body: #{response.body}"

      end

    end


end
