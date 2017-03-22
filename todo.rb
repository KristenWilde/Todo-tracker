require "sinatra"
require "sinatra/reloader"
require "sinatra/content_for"
require "tilt/erubis"

configure do
	enable :sessions
	set :session_secret, 'secret'
	set :erb, :escape_html => true
end

helpers do
	def all_complete?(list)
		todos = list[:todos]
		todos.size > 0 && todos.all? {|todo| todo[:completed]}
	end

	def list_class(list)
    "complete" if all_complete?(list)
	end

	def todos_remaining_count(list)
		list[:todos].select {|todo| !todo[:completed] }.size
	end

	def todos_count(list)
    list[:todos].size
	end

	def sorted_lists(lists, &block)
	  not_completed = []
	  completed = []
	  lists.each do |list|
	  	if all_complete?(list)
	  		completed << list
	  	else
	  		not_completed << list
	  	end 
	  end
	  (not_completed + completed).each(&block)
	end

	def sorted_todos(todos, &block)
		not_completed = []
		completed = []
		todos.each do |todo|
			if todo[:completed] 
				completed << todo
			else
				not_completed << todo
			end
		end
		not_completed.each(&block)
		completed.each(&block)
	end
end

before do
  session[:lists] ||= []
end

get "/" do
  redirect "/lists"
end

# view all the lists
get "/lists" do
  @lists = session[:lists] 
  erb :lists, layout: :layout
end

# Render the new list form
get "/lists/new" do
	erb :new_list, layout: :layout
end

def error_for_list_name(list_name, current_name=nil)
  if !(1..100).cover? list_name.size
		"List name must be between 1 and 100 characters."
	elsif session[:lists].any? {|list| list[:name] == list_name }
  	unless list_name == current_name
	  	"List name must be unique."
	  end
  end
end

def error_for_todo_name(name)
	if !(1..100).cover? name.size
		"Todo must be between 1 and 100 characters."
  end
end

def new_list_id
	max = session[:lists].map {|list| list[:list_id].to_i }.max || 0
	(max + 1).to_s
end

# create a new list on the "/lists" page.
post "/lists" do
	list_name = params[:list_name].strip
	error = error_for_list_name(list_name)
	if error
  	session[:error] = error
  	erb :new_list
  else
	  session[:lists] << {list_id: new_list_id, name: list_name, todos:[]}
  	session[:success] = "The list has been created."
  	redirect "/lists"
  end
end

# view a single list
get "/lists/:list_id" do
	@list_id = params[:list_id]
	@current_list = session[:lists].find {|list| list[:list_id] == @list_id}
	if @current_list
	  erb :single_list
	else
		session[:error] = "The list was not found"
		redirect "/lists"
	end
end

# edit an existing todo list
get "/lists/:list_id/edit" do
	@current_list = session[:lists].find {|list| list[:list_id] == params[:list_id]}
	erb :edit_list
end

# update an existing todo list
post "/lists/:list_id" do
	list_name = params[:list_name].strip
	@list = session[:lists].find {|list| list[:list_id] == params[:list_id]}
	error = error_for_list_name(list_name, @list[:name])
	if error
  	session[:error] = error
  	erb :edit_list
  else
	  @list[:name] = list_name
  	session[:success] = "The list has been updated."
  	redirect "/lists/#{params[:list_id]}"
  end
end

# delete a todo list
post "/lists/:list_id/delete" do
  session[:lists].delete_if {|list| list[:list_id] == params[:list_id]}
  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
  	"/lists"
  else
	  session[:success] = "The list has been deleted."
  	redirect "/lists"
  end
end

# mark all todos complete in a list
post "/lists/:list_id/complete" do
  current_list = session[:lists].find {|list| list[:list_id] == params[:list_id]}
  current_list[:todos].each do |todo|
  	todo[:completed] = true
  end	
  session[:success] = "All todos have been completed."
  redirect "/lists/#{list_num}"
end

def next_todo_id(todos)
  max = todos.map { |todo| todo[:id] }.max || 0
  max + 1
end

# add a todo to a list
post "/lists/:list_id/todos" do
	list_id = params[:list_id]
	@current_list = session[:lists].find {|list| list[:list_id] == list_id}
	todo_name = params[:todo].strip
	error = error_for_todo_name(todo_name)
	if error
		session[:error] = error
		erb :single_list
	else
		id = next_todo_id(@current_list[:todos])
		new_todo = {id: id, name: params[:todo], completed: false}
  	@current_list[:todos] << new_todo
  	session[:success] = "The todo was added"
  	redirect "/lists/#{params[:list_id]}"
  end
end

# delete a todo from a list
post "/lists/:list_id/todo/:id/delete" do
  current_list = session[:lists].find {|list| list[:list_id] == params[:list_id]}
  id = params[:id].to_i
  current_list[:todos].delete_if {|todo| todo[:id] == id}

  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    status 204
  else
	  session[:success] = "The todo has been deleted."
	  redirect "/lists/#{params[:list_id]}"
	end
end

# mark a todo complete
post "/lists/:list_id/todo/:id" do
	current_list = session[:lists].find {|list| list[:list_id] == params[:list_id]}
  id = params[:id].to_i
  is_completed = (params[:completed] == "true")
  todo = current_list[:todos].find {|todo| todo[:id] == id }
  todo[:completed] = is_completed
  session[:success] = "The todo has been updated."
  redirect "/lists/#{params[:list_id]}"
end









