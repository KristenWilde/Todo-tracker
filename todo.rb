require "sinatra"
require "sinatra/reloader"
require "sinatra/content_for"
require "tilt/erubis"

configure do
	enable :sessions
	set :session_secret, 'secret'
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
	  lists.each_with_index do |list, list_id|
	  	if all_complete?(list)
	  		completed << [list, list_id]
	  	else
	  		not_completed << [list, list_id]
	  	end 
	  end
	  (not_completed + completed).each(&block)
	end

	def sorted_todos(todos, &block)
		not_completed = {}
		completed = {}
		todos.each_with_index do |todo, id|
			if todo[:completed] 
				completed[id] = todo
			else
				not_completed[id] = todo
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

def error_for_todo_name(name, list_num)
	if !(1..100).cover? name.size
		"Todo must be between 1 and 100 characters."
  end
end

# create a new list on the "/lists" page.
post "/lists" do
	list_name = params[:list_name].strip
	error = error_for_list_name(list_name)
	if error
  	session[:error] = error
  	erb :new_list
  else
	  session[:lists] << {name: list_name, todos:[]}
  	session[:success] = "The list has been created."
  	redirect "/lists"
  end
end

# view a single list
get "/lists/:num" do
	@list_num = params[:num].to_i
	@current_list = session[:lists][@list_num]
  erb :single_list
end

# edit an existing todo list
get "/lists/:num/edit" do
	@current_list = session[:lists][params[:num].to_i]
	erb :edit_list
end

# update an existing todo list
post "/lists/:num" do
	list_name = params[:list_name].strip
	@list = session[:lists][params[:num].to_i]
	error = error_for_list_name(list_name, @list[:name])
	if error
  	session[:error] = error
  	erb :edit_list
  else
	  @list[:name] = list_name
  	session[:success] = "The list has been updated."
  	redirect "/lists/#{params[:num]}"
  end
end

post "/lists/:num/delete" do
  session[:lists].delete_at(params[:num].to_i)
  session[:success] = "The list has been deleted."
  redirect "/lists"
end

# mark all todos complete in a list
post "/lists/:list_num/complete" do
	list_num = params[:list_num].to_i
  session[:lists][list_num][:todos].each do |todo|
  	todo[:completed] = true
  end	
  session[:success] = "All todos have been completed."
  redirect "/lists/#{list_num}"
end


# add a todo to a list
post "/lists/:num/todos" do
	list_num = params[:num].to_i
	@current_list = session[:lists][list_num]
	todo_name = params[:todo].strip
	error = error_for_todo_name(todo_name, list_num)
	if error
		session[:error] = error
		erb :single_list
	else
		new_todo = {name: params[:todo], completed: false}
  	@current_list[:todos] << new_todo
  	session[:success] = "The todo was added"
  	redirect "/lists/#{list_num}"
  end
end

post "/lists/:list_num/todo/:todo_num/delete" do
  list_num = params[:list_num].to_i
  todo_num = params[:todo_num].to_i
  session[:lists][list_num][:todos].delete_at(todo_num)
  session[:success] = "The todo has been deleted."
  redirect "/lists/#{list_num}"
end

post "/lists/:list_num/todo/:todo_num" do
  list_num = params[:list_num].to_i
  todo_num = params[:todo_num].to_i
  is_completed = (params[:completed] == "true")
  session[:lists][list_num][:todos][todo_num][:completed] = is_completed
  session[:success] = "The todo has been updated."
  redirect "/lists/#{list_num}"
end









