require "sinatra"
require "sinatra/content_for"
require "tilt/erubis"

require_relative "database_persistence"

configure do
	enable :sessions
	set :session_secret, 'secret'
	set :erb, :escape_html => true
end 

configure(:development) do
  require "sinatra/reloader"
  also_reload "database_persistence.rb"
end

helpers do

  def load_list(id)
  p 'load list is running.'
    @storage.find_list(id)
  end

	def all_complete?(list)
		list[:todos_remaining_count] == 0 && list[:todos_count].positive?
	end

	def list_class(list)
    "complete" if all_complete?(list)
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

  def error_for_list_name(list_name, current_name=nil)
    if !(1..100).cover? list_name.size
      "List name must be between 1 and 100 characters."
    elsif @storage.all_lists.any? {|list| list[:name] == list_name }
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
end


before do
  @storage = DatabasePersistence.new(logger)
end

get "/" do
  redirect "/lists"
end

# view all the lists
get "/lists" do
  @lists = @storage.all_lists
  erb :lists, layout: :layout
end

# Render the new list form
get "/lists/new" do
	erb :new_list, layout: :layout
end

# create a new list on the "/lists" page.
post "/lists" do
	list_name = params[:list_name].strip
	error = error_for_list_name(list_name)
	if error
  	session[:error] = error
  	erb :new_list
  else
    @storage.create_new_list(list_name)
  	session[:success] = "The list has been created."
  	redirect "/lists"
  end
end

# view a single list
get "/lists/:list_id" do
	@list_id = params[:list_id].to_i
	@current_list =  load_list(@list_id)
  @todos = @storage.get_todos(@list_id) 
  if @current_list
	  erb :single_list
	else
		session[:error] = "The list was not found"
		redirect "/lists"
	end
end

# edit an existing todo list
get "/lists/:list_id/edit" do
	@current_list = load_list(params[:list_id].to_i)
	erb :edit_list
end

# update an existing todo list
post "/lists/:list_id" do
	list_name = params[:list_name].strip
  id = params[:list_id].to_i
	@list = load_list(id)
	
  error = error_for_list_name(list_name, @list[:name])
	if error
  	session[:error] = error
  	erb :edit_list
  else
	  @storage.update_list_name(id, list_name)
  	session[:success] = "The list has been updated."
  	redirect "/lists/#{params[:list_id]}"
  end
end

# delete a todo list
post "/lists/:list_id/delete" do
  list_id = params[:list_id].to_i
  @storage.delete_list(list_id) 
  
  session[:success] = "The list has been deleted."
  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
  	"/lists"
  else
  	redirect "/lists"
  end
end

# mark all todos complete in a list
post "/lists/:list_id/complete" do
  list_id = params[:list_id]
  @storage.mark_all_todos_complete(list_id)
  session[:success] = "All todos have been completed."
  redirect "/lists/#{list_id}"
end


# add a todo to a list
post "/lists/:list_id/todos" do
	list_id = params[:list_id].to_i
	@current_list = load_list(list_id)
	todo_name = params[:todo].strip
	error = error_for_todo_name(todo_name)
	if error
		session[:error] = error
		erb :single_list
	else
    @storage.create_new_todo(list_id, todo_name)
  	session[:success] = "The todo was added"
  	redirect "/lists/#{params[:list_id]}"
  end
end

# delete a todo from a list
post "/lists/:list_id/todo/:todo_id/delete" do
  list_id = params[:list_id].to_i
  todo_id = params[:todo_id].to_i
  @storage.delete_todo_from_list(list_id, todo_id)

  session[:success] = "The todo has been deleted."
  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    status 204
  else
	  redirect "/lists/#{params[:list_id]}"
	end
end

# mark a todo complete
post "/lists/:list_id/todo/:todo_id" do
  list_id = params[:list_id].to_i
  todo_id = params[:todo_id].to_i
  new_status = (params[:completed] == 'true')
  @storage.update_todo_status(list_id, todo_id, new_status)

  session[:success] = "The todo has been updated."
  redirect "/lists/#{params[:list_id]}"
end
