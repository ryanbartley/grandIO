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
  property :firstname     , String
  property :lastname      , String
  property :email         , String  , :format => email_address, :unique_index => true
  property :password_salt , String
  property :password_hash , String
  property :teacher       , Boolean , :default => false
  property :interest1     , String
  property :interest2     , String
  property :interest3     , String
  property :interest4     , String

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

  property :slug        , String,    :key => true, :unique_index => true, :default => lambda { | resource, prop| resource.title.downcase.gsub " ", "-" }
  property :title       , String,    :required => true
  property :date        , DateTime,  :required => true
  property :instructor  , String,    :required => true
  property :description , Text,      :required => true
  
  has n, :persons, :through => Resource, :order => [ :date.desc ]

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
        return session[:email]
    end

end

def upcomingCoursesFunc

    allClasses = Course.all
    #count up all the courses that are in the next
    #couple of days so that we can display them to
    #people coming to the site
    if(allClasses)

      #get the exact time on the server when a person starts
      thisTime = Time.new

        for thisClass in allClasses
            
            #check the time and date of the classes and 
            #figure out if it's within three days. This
            #needs work
            if thisClass.Date - thisTime.local.to_date < 3
               upcomingClasses += thisClass
            end

        end

        #Once I work out the above this will sort the classes 
        #and return the sorted classes
        #sortingTheClasses(upcomingClasses)
    end

end

before do
    session[:email] = nil
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

get "/testsave" do
    p = Person.new

    p.firstname = "hello"

    p.save
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
        
        p = Person.create(:firstname => params[:firstname], 
                          :lastname => params[:lastname], 
                          :email => params[:email],
                          :password_salt => password_salt,
                          :password_hash => password_hash,
                          :teacher => false)

        raise Exception, p
        #p = Person.new
  #
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
      user = match
      #raise Exception, user
      if user.password_hash == BCrypt::Engine.hash_secret(params[:password], user.password_salt)
          session[:email] = user.email
          session[:year] = user.year
          

          if user.class1 != nil
            @class1orig = whichClasses(user.class1)
            @class1 = user.class1
      else
        #raise Exception, "i'm nil"
        @class1orig = "None"
        @class1 = "none"
      end 
      
      if user.class2 != nil
            @class2orig = whichClasses(user.class2)
            @class2 = user.class2
      else
        #raise Exception, "i'm nil"
        @class2orig = "None"
        @class2 = "none"
      end 
      
      if user.class3 != nil
            @class3orig = whichClasses(user.class3)
            @class3 = user.class3
      else
        #raise Exception, "i'm nil"
        @class3orig = "None"
        @class3 = "none"
      end 
      
      if user.class4 != nil
            @class4orig = whichClasses(user.class4)
            @class4 = user.class4
      else
        #raise Exception, "i'm nil"
        @class4orig = "None"
        @class4 = "none"
      end 
      
      if user.class5 != nil
            @class5orig = whichClasses(user.class5)
            @class5 = user.class5
      else
        #raise Exception, "i'm nil"
        @class5orig = "None"
        @class5 = "none"
      end 
      
          erb :profile
          
      else 
        erb :error
      end
    else
      erb :error
    end
end

get '/about' do

  @page_title = "About"

  erb :about
end


get '/addcourse' do
  
  @page_title = "Add Course"
  
  erb :addcourse
  
end

get '/courses' do
  
  @courses = Course.all(:order=>[:date.desc])
  @page_title = "Courses"
  
  erb :courses
  
end

get '/courses/:title' do
  @courses = Course.all 
  @this_course = Course.first(:title => params[:title])
  @page_title = ":title"

  erb :single_course

end

post '/login' do

    login = Person.first(:email => params[:email])

end

post '/newcourse' do
  course = Course.new
  
  course.id = params[:id]
  course.title = params[:title]
  course.instructor = params[:instructor]
  course.date = params[:date]
  course.description = params[:description]
 
  
  if course.save
  
    status 201
    output = ""
  
     output += <<-HTML
     Sucess!
     <br>
     <a href = "/addcourse">Add another course</a>
     <br>
     <br>
     <a href = "/courses">See all course</a>
     <br>
     <br>
    <h2><a href=  "/erase">Edit entries</a></h2>
    <br>
    
     HTML
    
    
    
  else
    status 412
    
    output = ""
    output += <<-HTML
    Error - Could not enter course
    <br>
    <br>
    <a href="/addcourse">Try Again</a>
    <br>
    HTML
  end
  output
  
end


  
  


