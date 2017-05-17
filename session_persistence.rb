
class SessionPersistence

  def initialize(session)
    @session = session
    @session[:lists] ||= []
  end

  def all_lists
    @session[:lists]
  end

  def create_new_list(list_name)
    id = next_element_id(all_lists)
    new_list = {id: id, name: list_name, todos:[]}
    @session[:lists] << new_list
  end

  def find_list(list_id)
    @session[:lists].find {|list| list[:id] == list_id}
  end

  def update_list_name(id, new_name)
    find_list(id)[:name] = new_name
  end

  def mark_all_todos_complete(id)
    list = find_list(id)
    list[:todos].each do |todo|
      todo[:completed] = true
    end 
  end

  def create_new_todo(list_id, todo_name)
    todos = find_list(list_id)[:todos]
    id = next_element_id(todos)
    new_todo = {id: id, name: todo_name, completed: false}
    todos << new_todo
  end

  def delete_list(id)
    all_lists.delete(find_list(id))
  end

  def delete_todo_from_list(list_id, todo_id)
    list = find_list(list_id)
    list[:todos].delete_if { |todo| todo[:id] == todo_id }
  end

  def update_todo_status(list_id, todo_id, new_status)
    todo = find_list(list_id)[:todos].find { |t| t[:id] == todo_id }
    todo[:completed] = new_status
  end

  private

  def next_element_id(collection)
    max = collection.map { |element| element[:id] }.max || 0
    max + 1
  end
end