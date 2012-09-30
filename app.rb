require 'sinatra'
require 'sinatra/reloader'

require 'oauth2'
require 'open-uri'

ig_client_id = ""
ig_secret = ""
redirect_uri = uri('/iga')


hashtag = ""

client = OAuth2::Client.new(
	ig_client_id, 
	ig_secret,
 :site => "https://api.instagram.com",
 :authorize_url => "/oauth/authorize/",
 :token_url => "/oauth/access_token"
 )
token = nil

atoken = nil

imgs = []


#start authentication
get "/start" do
	redirect client.auth_code.authorize_url(:redirect_uri => redirect_uri, )
end

#authentication callback
get '/iga' do

	atoken = client.auth_code.get_token(
		params[:code],
		:redirect_uri => redirect_uri
	)

	
	token = atoken.token
	File.open("atoken.txt", 'w') {|f| f.write(token) }

	redirect to('/')

end

get '/' do


	f = File.open("atoken.txt", "r")
	token = f.read

	c = OAuth2::AccessToken.new(client, token, {:mode=>:query, :param_name=>:"access_token"})

	
	uri = "/v1/tags/#{hashtag}/media/recent"

	@imgs = []

	nextu = "0"
	

	while nextu != nil do
		r = c.get(uri)
		plist =  r.parsed["data"]
		p r.parsed["pagination"]
		dostuff(plist)
		if r.parsed["pagination"].has_key?("next_url")

			

			nextu = r.parsed["pagination"]["next_url"]
			uri = nextu
		else
			nextu = nil

		end
		
	end

	imgs = @imgs
	

	# dostuff(plist)

	#p @imgs.length

	erb :display
end

get '/zip' do
	zipup()
	"<a href=\"archive.zip\">Archive</a"
end

def dostuff(data)

	data.each do |k,v|
		@imgs.push(k["images"]["standard_resolution"]["url"])


		fname =  k["user"]["username"] + "-" + k["created_time"] + ".jpg"

		if !File.exists?("imgs/#{fname}")

			open("imgs/#{fname}", 'wb') do |file|
			  file << open(k["images"]["standard_resolution"]["url"]).read
			end
		end
		

	end
end

def zipup()
	Dir.chdir('imgs'){
	  	system( "7za -tzip a ../public/archive.zip ." )
	}

	
end