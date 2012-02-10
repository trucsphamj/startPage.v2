require 'sinatra'
require 'redis'

r = Redis.new

before do
   $suggestedLinks = {"http://www.bankofamerica.com" => "Bank Of America", "http://www.fullerton.edu" => "Cal State Fulllerton", 
   "http://www.youtube.com" => "YouTube", "http://www.facebook.com" => "Facebook", "http://csuf.kenytt.net" => "Web Programming CPSC 473, CSU Fullerton",
   "http://www.frys.com" => "Frys Electronic", "http://www.nasa.com" => "NASA", "http://www.ruby-doc.org/core-1.9.3/" => "Ruby API",
   "http://redis.io/commands" => "Redis API"}
   $toBeDeletedLinksHash = {}
end

$sitesHash = {}
$toBeDeletedLinksHash = {}

configure do
   enable :sessions
end

get '/register' do
   erb :register
end

post '/register' do
   if(r.hexists 'userInfo', params[:email])
      @duplicate = true
   else
      r.hset 'userInfo', params[:email], params[:password]
   end
   erb :register
end


#The homepage displays all the favorite URLs
get '/' do  
   if(session[:email] == nil)
      r.select 1
      $sitesHash = r.hgetall 'favoriteURLs1'
   else 
      r.select 0
      $sitesHash = r.hgetall 'favoriteURLs0'
   end
   erb :index
end

#"edit" from Truc's code is called "customize" in this code
get '/edit' do
     erb :customize
end

get '/customize' do
   if(session[:email] == nil)
      r.select 1
      $sitesHash = r.hgetall 'favoriteURLs1'
      $toBeDeletedLinksHash = r.hgetall 'favoriteURLs1'
   else 
      r.select 0
      $sitesHash = r.hgetall 'favoriteURLs0'
      $toBeDeletedLinksHash = r.hgetall 'favoriteURLs0'
   end
   erb :customize
end

get '/login' do
    erb :login
end


#login page
post '/login' do
  r.select 0

  @invalidInfo = false
   if (!(r.hexists 'userInfo', params[:email]) && !(r.hexists 'userInfo', params[:password]))
     @invalidInfo = true
   end

  if ((r.hexists 'userInfo', params[:email]) && !((r.hget 'userInfo', params[:email]).eql? params[:password]) )
     @invalidInfo = true
  else
     $toBeDeletedLinksHash = r.hgetall 'toBeDeletedLinks0'
     session[:email] = params[:email]
  end
  erb :login
end

#addURL and removeURL are form actions performed on the /customize page.
post '/addURL' do
   @hiddenURL = params[:hiddenURL]
   @url = params[:myURL]
   @siteName = params[:siteName]
   
   if(session[:email] == nil)
      r.select 1
      if((@hiddenURL != nil) && (@url == nil))
   	 r.hsetnx 'favoriteURLs1',@hiddenURL, @siteName 
      else
        r.hsetnx 'favoriteURLs1', @url, @siteName
      end
   else
      r.select 0
      if((@hiddenURL != nil) && (@url == nil))
   	 r.hsetnx 'favoriteURLs0',@hiddenURL, @siteName 
      else
        r.hsetnx 'favoriteURLs0', @url, @siteName
      end
   end
   redirect '/'
end

post '/removeURL' do
   if(session[:email] == nil)
      r.select 1
      @hiddenURL = params[:hiddenURL]
      @siteName = params[:siteName]
      $suggestedLinks[@hiddenURL] = @siteName
      r.hdel 'favoriteURLs1', @hiddenURL
      redirect '/'
   else
      r.select 0
      @hiddenURL = params[:hiddenURL]
      @siteName = params[:siteName]
      $suggestedLinks[@hiddenURL] = @siteName
      r.hdel 'favoriteURLs0', @hiddenURL
      redirect '/'
   end  
end

get '/logout' do
   r.select 1
   r.flushdb 
   session.clear  
   redirect '/'
end
   

#this section is no longer needed since the favorite URLs will be displayed on the front page.
get '/mySites' do
   $sitesHash = r.hgetall 'favoriteURLs'
   erb :index
end
