require 'rubygems'
require 'sinatra'
require 'data_mapper'
require 'date'
require 'dm-core'
require 'bcrypt'
require 'dm-timestamps'

enable :sessions

DataMapper::setup(:default, {:adapter => 'yaml', :path => 'db'})

DataMapper::Model.raise_on_save_failure = true

class Person
  include DataMapper::Resource
  
  property :id            , Serial
  property :firstname     , String  , :required => true
  property :lastname      , String  , :required => true
  property :email         , String  , :required => true, :format => :email_address, :unique => true
  property :password_salt , String  , :required => true
  property :password_hash , Text    , :required => true
  property :teacher       , Boolean , :default => false, :required => false
  property :interest1     , String  , :required => false
  property :interest2     , String  , :required => false
  property :interest3     , String  , :required => false
  property :interest4     , String  , :required => false

  #belongs_to :courses     , :required => false

  has n, :courses, :through => Resource

  def email= new_email
    @email = new_email.downcase
  end

  def becomingATeacher
    @teacher = true
  end

end


class Course
  include DataMapper::Resource

  property :slug            , String,    :key => true, :unique_index => true, :default => lambda { | resource, prop| resource.title.downcase.gsub " ", "-" }
  property :title           , String,    :required => true
  property :date            , DateTime,  :required => true
  property :instructorfirst , String,    :required => true
  property :instructorlast  , String,    :required => true
  property :description     , Text,      :required => true
  
  
  has n, :persons, :through => Resource

  def attending(student)

  end

end

DataMapper.auto_upgrade!
DataMapper.finalize

#this is to the sort the classes by date.
def sortingTheClasses (upcomingClasses)
    #i need to take the values out of the database and 
    #make a hash then return the hash so that it can 
    #access the data members better by date. 
    upcomingClasses.sort_by{ |k, v| v[:date]}.reverse
end

helpers do
    
    def login?
        if session[:email] == nil
          return false
        else
          return true
        end
    end

    def username
        session[:email]
    end

    def firstname
        session[:firstname] 
    end

    def lastname
        session[:lastname]
    end

end

def upcomingCoursesFunc

    Course.all(:order => [ :date.asc ])
    #count up all the courses that are in the next
    #couple of days so that we can display them to
    #people coming to the site
    #if(allClasses)
    #
    #  #get the exact time on the server when a person starts
    #  thisTime = Time.new
    #
    #    for thisClass in allClasses
    #        
    #        #check the time and date of the classes and 
    #        #figure out if it's within three days. This
    #        #needs work
    #        if thisClass.Date - thisTime.local.to_date < 3
    #           upcomingClasses += thisClass
    #        end
    #
    #    end
    #
    #    #Once I work out the above this will sort the classes 
    #    #and return the sorted classes
    #    #sortingTheClasses(upcomingClasses)
    #end

end

before do
    #session[:email] = nil
    @upcomingCourses = upcomingCoursesFunc
end

# Main route  - this is the form where we take the input
get '/' do

  @page_title = "GrandIO"
  
  erb :index
  
end

get '/signup' do

  @page_title = "Sign Up"
  @page_heading = "Enter a new username and password!"

  erb :signup

end

post "/signedup" do

  user = Person.first(:email => params[:email])
  
  #make sure there isn't a user already listed in the database
  if !user 
    
    #make sure the passwords match
    if params[:password] == params[:checkpassword]

        #generate the encryption
        password_salt = BCrypt::Engine.generate_salt
        password_hash = BCrypt::Engine.hash_secret(params[:password], password_salt)
    
        #create the session id
        session[:email] = params[:email]
        #raise Exception, session[:email]
        
        #create a new person entry
        
        @p = Person.create(:firstname => params[:firstname], 
                          :lastname => params[:lastname], 
                          :email => params[:email],
                          :password_salt => password_salt,
                          :password_hash => password_hash,
                          :teacher => false)

        if @p.save

        else
            raise Exception, @p.errors.inspect
        end
        #p = Person.new
        #p.email = session[:email]
        #p.password_salt = password_salt
        #p.password_hash = password_hash
        #p.firstname = params[:firstname]
        #p.lastname = params[:lastname]
        #p.teacher = false
        #raise Exception, p.save
        #p.save

        
        @page_title = "Please Choose Classes"
        @page_heading = "Please Enter Your Username And Password!"
        @forgotPassword = ""
        erb :profile
    else 
      @page_title = "Please Retype Your Password"
      @page_heading = "Please retype your password!"
      @forgotPassword = ""
      erb :signup
    end
  else 
      @page_title = "Please Check email"
      @page_heading = "That email is already in use!"
      @forgotPassword = "Forgot Password?"
      erb :signup
  end

end

post "/login" do

  match = Person.first(:email => params[:email])

    if match
        
        @p = match
        #raise Exception, @p
        
        if @p.password_hash == BCrypt::Engine.hash_secret(params[:password], @p.password_salt)
            
            session[:email] = @p.email
            session[:firstname] = @p.firstname.capitalize
            session[:lastname] = @p.lastname.capitalize
            
            redirect "http://itp.nyu.edu/~rtb288/sinatra/grandio/profile"
            
        else 
  
            "The Password didn't match"
        
        end
    
    else
    
        "You didn't get a match"
    
    end

end

get '/profile' do

    @p = Person.first(:email => session[:email])

    if @p 
        #raise Exception, @p
        @page_title = "Your Profile"
        @page_heading = "Your Profile"
        erb :profile
    else 
        "You need to login"
    end

end

post '/updateprofile' do

    p = Person.first(:email => session[:email])

    if p

        if params[:password] != "" && params[:checkpassword] != ""
            if p.update(:firstname => params[:firstname], 
                    :lastname => params[:lastname], 
                    :email => params[:email],
                    :password_salt => params[:password],
                    :password_hash => params[:checkpassword],
                    :teacher => params[:group1], 
                    :interest1 => params[:interests])
            else
                raise Exception, p.errors.inspect
            end
        else
            if p.update(:firstname => params[:firstname], 
                    :lastname => params[:lastname], 
                    :email => params[:email],
                    :password_salt => p.password_salt,
                    :password_hash => p.password_hash,
                    :teacher => params[:group1], 
                    :interest1 => params[:interests])
            else
                raise Exception, p.errors.inspect
            end
        end

        redirect "http://itp.nyu.edu/~rtb288/sinatra/grandio/profile"

    else
        "You didn't update anything idiot"
    end

end

get '/logout' do

    session[:firstname] = nil
    session[:lastname] = nil
    session[:email] = nil
    redirect "http://itp.nyu.edu/~rtb288/sinatra/grandio/"

end

get '/about' do

    @page_title = "About Us"
    erb :about

end


get '/addcourse' do
  
    @page_title = "Add Course"
    erb :addcourse
  
end

get '/courses' do
  
    if session[:email]
      p = Person.first(:email => session[:email])
  
      if p.teacher == true
          @addcourses = true
      else 
          @addcourses = false
      end
    end
  
      @courses = Course.all(:order=>[:date.desc])
      @page_title = "Courses"
      
      erb :courses
  
end

get '/courses/:title' do

    @courses = Course.all 
    @this_course = Course.first(:title => params[:title])
    #raise Exception, @date = @this_course.strftime([format='%A %d %b %Y'])
    @page_title = ":title"
  
    erb :single_course

end

post '/newcourse' do
  
    p = Person.first(:email => session[:email])
    
    if p.teacher == true
  

      if @course = Course.create(:date => params[:date],
                             :instructorfirst => p.firstname,
                             :instructorlast => p.lastname,
                             :title => params[:title],
                             :description => params[:description])
        
        if @course.persons << p 

          if p.courses << @course

            if @course.save && p.save

                redirect "http://itp.nyu.edu/~rtb288/sinatra/grandio/courses"
            else
                raise Exception, "I'm inside"
                "Your course didn't save." 
            end
          else
            "Your courses didn't setup with the person"
          end
        else
            "It didn't save"
        end
      else
        raise Exception, course.errors.inspect
      end
    else
        "You're not a teacher"
    end     
end


  
  


