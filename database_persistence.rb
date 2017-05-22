require 'pg'

class DatabasePersistence

  def initialize(logger)
    @db = PG.connect(dbname: DATABASE_URL)
    @logger = logger
  end

  def query(statement, *params)
    @logger.info "#{statement}: #{params}"
    @db.exec_params(statement, params)
  end

  def all_lists
    sql = <<~QUERY
      select lists.*, 
        count(todos.id) as todos_count,
        count(nullif(todos.completed, true)) as todos_remaining_count
        from lists
        left join todos on todos.list_id = lists.id
        group by lists.id
      QUERY
    result = query(sql)

    result.map do |tuple|
      tuple_to_list_hash(tuple)
    end
  end

  def find_list(list_id)
    sql = <<~QUERY
      select lists.*, 
        count(todos.id) as todos_count,
        count(nullif(todos.completed, true)) as todos_remaining_count
        from lists
        left join todos on todos.list_id = lists.id
        where lists.id = $1
        group by lists.id
      QUERY
    result = query(sql, list_id)
    tuple_to_list_hash(result.first)
  end

  def create_new_list(list_name)
    sql = "insert into lists (name) values ($1)"
    query(sql, list_name)
  end

  def update_list_name(id, new_name)
    sql = "update lists set name = $1 where id = $2"
    query(sql, new_name, id)
  end

  def mark_all_todos_complete(id)
    sql = "update todos set completed = true where list_id = $1"
    query(sql, id)
  end

  def create_new_todo(list_id, todo_name)
    sql = "insert into todos (list_id, name) values ($1, $2)"
    query(sql, list_id, todo_name)
  end

  def delete_list(id)
    sql = "delete from lists where id = $1"
    query(sql, id)
  end

  def delete_todo_from_list(list_id, todo_id)
    sql = "delete from todos where list_id = $1 and id = $2"
    query(sql, list_id, todo_id)
  end

  def update_todo_status(list_id, todo_id, new_status)
    sql = "update todos set completed = $1 where id = $2 and list_id = $3"
    query(sql, new_status, todo_id, list_id)
  end

  def get_todos(list_id)
    sql = "select * from todos where list_id = $1"
    result = query(sql, list_id)
    result.map do |tuple|
      { id: tuple["id"].to_i, 
        name: tuple["name"], 
        completed: tuple["completed"] == 't'}
    end
  end

  private

  def tuple_to_list_hash(tuple)
    { id: tuple["id"].to_i, 
      name: tuple["name"], 
      todos_count: tuple["todos_count"].to_i,
      todos_remaining_count: tuple["todos_remaining_count"].to_i }
  end
end