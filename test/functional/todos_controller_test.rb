require File.dirname(__FILE__) + '/../test_helper'
require 'todos_controller'

# Re-raise errors caught by the controller.
class TodosController; def rescue_action(e) raise e end; end

class TodosControllerTest < Test::Rails::TestCase
  fixtures :users, :preferences, :projects, :contexts, :todos, :tags, :taggings
  
  def setup
    @controller = TodosController.new
    @request, @response = ActionController::TestRequest.new, ActionController::TestResponse.new
  end

  def test_get_index_when_not_logged_in
    get :index
    assert_redirected_to :controller => 'login', :action => 'login'
  end
  
  def test_not_done_counts
    login_as(:admin_user)
    get :index
    assert_equal 2, assigns['project_not_done_counts'][projects(:timemachine).id]
    assert_equal 3, assigns['context_not_done_counts'][contexts(:call).id]
    assert_equal 1, assigns['context_not_done_counts'][contexts(:lab).id]
  end
  
  def test_tag_is_retrieved_properly
    login_as(:admin_user)
    get :index
    t = assigns['not_done_todos'].find{|t| t.id == 2}
    assert_equal 1, t.tags.count
    assert_equal 'foo', t.tags[0].name
    assert !t.starred?
  end
  
  def test_not_done_counts_after_hiding_project
    p = Project.find(1)
    p.hide!
    p.save!
    login_as(:admin_user)
    get :index
    assert_equal nil, assigns['project_not_done_counts'][projects(:timemachine).id]
    assert_equal 2, assigns['context_not_done_counts'][contexts(:call).id]
    assert_equal nil, assigns['context_not_done_counts'][contexts(:lab).id]
  end
  
  def test_not_done_counts_after_hiding_and_unhiding_project
    p = Project.find(1)
    p.hide!
    p.save!
    p.activate!
    p.save!
    login_as(:admin_user)
    get :index
    assert_equal 2, assigns['project_not_done_counts'][projects(:timemachine).id]
    assert_equal 3, assigns['context_not_done_counts'][contexts(:call).id]
    assert_equal 1, assigns['context_not_done_counts'][contexts(:lab).id]
  end
  
  def test_deferred_count_for_project_source_view
    login_as(:admin_user)
    xhr :post, :toggle_check, :id => 5, :_source_view => 'project' 
    assert_equal 1, assigns['deferred_count']
    xhr :post, :toggle_check, :id => 15, :_source_view => 'project' 
    assert_equal 0, assigns['deferred_count']
  end
  
  def test_destroy_todo
    login_as(:admin_user)
    xhr :post, :destroy, :id => 1, :_source_view => 'todo'
    assert_rjs :page, "todo_1", :remove
    # #assert_rjs :replace_html, "badge-count", '9'
  end
  
  def test_create_todo
    assert_difference Todo, :count do
      login_as(:admin_user)
      put :create, :_source_view => 'todo', "context_name"=>"library", "project_name"=>"Build a working time machine", "todo"=>{"notes"=>"", "description"=>"Call Warren Buffet to find out how much he makes per day", "due"=>"30/11/2006"}, "tag_list"=>"foo bar"
    end
  end
  
  def test_create_todo_via_xml
    login_as(:admin_user)
    assert_difference Todo, :count do
      put :create, :format => "xml", "request" => { "context_name"=>"library", "project_name"=>"Build a working time machine", "todo"=>{"notes"=>"", "description"=>"Call Warren Buffet to find out how much he makes per day", "due"=>"30/11/2006"}, "tag_list"=>"foo bar" }
      assert_response 201
    end
  end

  def test_fail_to_create_todo_via_xml
    login_as(:admin_user)
    # #try to create with no context, which is not valid
    put :create, :format => "xml", "request" => { "project_name"=>"Build a working time machine", "todo"=>{"notes"=>"", "description"=>"Call Warren Buffet to find out how much he makes per day", "due"=>"30/11/2006"}, "tag_list"=>"foo bar" }
    assert_response 422
    assert_xml_select "errors" do
      assert_xml_select "error", "Context can't be blank"
    end
  end
  
  def test_create_deferred_todo
    original_todo_count = Todo.count
    login_as(:admin_user)
    put :create, :_source_view => 'todo', "context_name"=>"library", "project_name"=>"Build a working time machine", "todo"=>{"notes"=>"", "description"=>"Call Warren Buffet to find out how much he makes per day", "due"=>"30/11/2026", 'show_from' => '30/10/2026'}, "tag_list"=>"foo bar"
    assert_equal original_todo_count + 1, Todo.count
  end
  
  def test_update_todo_project
    t = Todo.find(1)
    login_as(:admin_user)
    xhr :post, :update, :id => 1, :_source_view => 'todo', "context_name"=>"library", "project_name"=>"Build a working time machine", "todo"=>{"id"=>"1", "notes"=>"", "description"=>"Call Warren Buffet to find out how much he makes per day", "due"=>"30/11/2006"}, "tag_list"=>"foo bar"
    t = Todo.find(1)
    assert_equal 1, t.project_id
  end
  
  def test_update_todo_project_to_none
    t = Todo.find(1)
    login_as(:admin_user)
    xhr :post, :update, :id => 1, :_source_view => 'todo', "context_name"=>"library", "project_name"=>"None", "todo"=>{"id"=>"1", "notes"=>"", "description"=>"Call Warren Buffet to find out how much he makes per day", "due"=>"30/11/2006"}, "tag_list"=>"foo bar"
    t = Todo.find(1)
    assert_nil t.project_id
  end
  
  def test_update_todo_to_deferred_is_reflected_in_badge_count
    login_as(:admin_user)
    get :index
    assert_equal 10, assigns['count']
    xhr :post, :update, :id => 1, :_source_view => 'todo', "context_name"=>"library", "project_name"=>"Make more money than Billy Gates", "todo"=>{"id"=>"1", "notes"=>"", "description"=>"Call Warren Buffet to find out how much he makes per day", "due"=>"30/11/2006", "show_from"=>"30/11/2030"}, "tag_list"=>"foo bar"
    assert_equal 9, assigns['down_count']
  end
  
  def test_update_todo
    t = Todo.find(1)
    login_as(:admin_user)
    xhr :post, :update, :id => 1, :_source_view => 'todo', "todo"=>{"context_id"=>"1", "project_id"=>"2", "id"=>"1", "notes"=>"", "description"=>"Call Warren Buffet to find out how much he makes per day", "due"=>"30/11/2006"}, "tag_list"=>"foo, bar"
    t = Todo.find(1)
    assert_equal "Call Warren Buffet to find out how much he makes per day", t.description
    assert_equal "foo, bar", t.tag_list
    expected = Date.new(2006,11,30)
    actual = t.due
    assert_equal expected, actual, "Expected #{expected.to_s(:db)}, was #{actual.to_s(:db)}"
  end

  def test_update_todos_with_blank_project_name
    t = Todo.find(1)
    login_as(:admin_user)
    xhr :post, :update, :id => 1, :_source_view => 'todo', :project_name => '', "todo"=>{"id"=>"1", "notes"=>"", "description"=>"Call Warren Buffet to find out how much he makes per day", "due"=>"30/11/2006"}, "tag_list"=>"foo, bar"
    t.reload
    assert t.project.nil?
  end
  
  def test_update_todo_tags_to_none
    t = Todo.find(1)
    login_as(:admin_user)
    xhr :post, :update, :id => 1, :_source_view => 'todo', "todo"=>{"context_id"=>"1", "project_id"=>"2", "id"=>"1", "notes"=>"", "description"=>"Call Warren Buffet to find out how much he makes per day", "due"=>"30/11/2006"}, "tag_list"=>""
    t = Todo.find(1)
    assert_equal true, t.tag_list.empty?
  end

  def test_update_todo_tags_with_whitespace_and_dots
    t = Todo.find(1)
    login_as(:admin_user)
    taglist = "  one  ,  two,three    ,four, 8.1.2, version1.5"
    xhr :post, :update, :id => 1, :_source_view => 'todo', "todo"=>{"context_id"=>"1", "project_id"=>"2", "id"=>"1", "notes"=>"", "description"=>"Call Warren Buffet to find out how much he makes per day", "due"=>"30/11/2006"}, "tag_list"=>taglist
    t = Todo.find(1)
    assert_equal "one, two, three, four, 8.1.2, version1.5", t.tag_list
  end

  def test_find_tagged_with
    login_as(:admin_user)
    @user = User.find(@request.session['user_id'])
    tag = Tag.find_by_name('foo').todos
    @tagged = tag.find(:all, :conditions => ['taggings.user_id = ?', @user.id]).size
    get :tag, :name => 'foo'
    assert_response :success
    assert_equal 3, @tagged
  end
  
  def test_rss_feed
    login_as(:admin_user)
    get :index, { :format => "rss" }
    assert_equal 'application/rss+xml', @response.content_type
    # #puts @response.body

    assert_xml_select 'rss[version="2.0"]' do
      assert_select 'channel' do
        assert_select '>title', 'Tracks Actions'
        assert_select '>description', "Actions for #{users(:admin_user).display_name}"
        assert_select 'language', 'en-us'
        assert_select 'ttl', '40'
        assert_select 'item', 10 do
          assert_select 'title', /.+/
          assert_select 'description', /.*/
          assert_select 'link', %r{http://test.host/contexts/.+}
          assert_select 'guid', %r{http://test.host/todos/.+}
          assert_select 'pubDate', projects(:timemachine).updated_at.to_s(:rfc822)
        end
      end
    end
  end

  def test_rss_feed_with_limit
    login_as(:admin_user)
    get :index, { :format => "rss", :limit => '5' }

    assert_xml_select 'rss[version="2.0"]' do
      assert_select 'channel' do
        assert_select '>title', 'Tracks Actions'
        assert_select '>description', "Actions for #{users(:admin_user).display_name}"
        assert_select 'item', 5 do
          assert_select 'title', /.+/
          assert_select 'description', /.*/
        end
      end
    end
  end
  
  def test_rss_feed_not_accessible_to_anonymous_user_without_token
    login_as nil
    get :index, { :format => "rss" }
    assert_response 401
  end

  def test_rss_feed_not_accessible_to_anonymous_user_with_invalid_token
    login_as nil
    get :index, { :format => "rss", :token => 'foo'  }
    assert_response 401
  end

  def test_rss_feed_accessible_to_anonymous_user_with_valid_token
    login_as nil
    get :index, { :format => "rss", :token => users(:admin_user).token }
    assert_response :ok
  end

  def test_atom_feed_content
    login_as :admin_user
    get :index, { :format => "atom" }
    assert_equal 'application/atom+xml', @response.content_type
    # #puts @response.body

    assert_xml_select 'feed[xmlns="http://www.w3.org/2005/Atom"]' do
      assert_xml_select '>title', 'Tracks Actions'
      assert_xml_select '>subtitle', "Actions for #{users(:admin_user).display_name}"
      assert_xml_select 'entry', 10 do
        assert_xml_select 'title', /.+/
        assert_xml_select 'content[type="html"]', /.*/
        assert_xml_select 'published', /(#{Regexp.escape(projects(:timemachine).updated_at.xmlschema)}|#{Regexp.escape(projects(:moremoney).updated_at.xmlschema)})/
      end
    end
  end

  def test_atom_feed_not_accessible_to_anonymous_user_without_token
    login_as nil
    get :index, { :format => "atom" }
    assert_response 401
  end

  def test_atom_feed_not_accessible_to_anonymous_user_with_invalid_token
    login_as nil
    get :index, { :format => "atom", :token => 'foo'  }
    assert_response 401
  end

  def test_atom_feed_accessible_to_anonymous_user_with_valid_token
    login_as nil
    get :index, { :format => "atom", :token => users(:admin_user).token }
    assert_response :ok
  end

  def test_text_feed_content
    login_as(:admin_user)
    get :index, { :format => "txt" }
    assert_equal 'text/plain', @response.content_type
    assert !(/&nbsp;/.match(@response.body))
    # #puts @response.body
  end

  def test_text_feed_not_accessible_to_anonymous_user_without_token
    login_as nil
    get :index, { :format => "txt" }
    assert_response 401
  end

  def test_text_feed_not_accessible_to_anonymous_user_with_invalid_token
    login_as nil
    get :index, { :format => "txt", :token => 'foo'  }
    assert_response 401
  end

  def test_text_feed_accessible_to_anonymous_user_with_valid_token
    login_as nil
    get :index, { :format => "txt", :token => users(:admin_user).token }
    assert_response :ok
  end

  def test_ical_feed_content
    login_as :admin_user
    get :index, { :format => "ics" }
    assert_equal 'text/calendar', @response.content_type
    assert !(/&nbsp;/.match(@response.body))
    # #puts @response.body
  end
  
  def test_mobile_index_uses_text_html_content_type
    login_as(:admin_user)
    get :index, { :format => "m" }
    assert_equal 'text/html', @response.content_type
  end
  
  def test_mobile_index_assigns_down_count
    login_as(:admin_user)
    get :index, { :format => "m" }
    assert_equal 10, assigns['down_count']
  end
  
  def test_mobile_create_action_creates_a_new_todo
    login_as(:admin_user)
    post :create, {"format"=>"m", "todo"=>{"context_id"=>"2",
        "due(1i)"=>"2007", "due(2i)"=>"1", "due(3i)"=>"2",
        "show_from(1i)"=>"", "show_from(2i)"=>"", "show_from(3i)"=>"",
        "project_id"=>"1", 
        "notes"=>"test notes", "description"=>"test_mobile_create_action", "state"=>"0"}}
    t = Todo.find_by_description("test_mobile_create_action")
    assert_not_nil t
    assert_equal 2, t.context_id
    assert_equal 1, t.project_id
    assert t.active?
    assert_equal 'test notes', t.notes
    assert_nil t.show_from
    assert_equal Date.new(2007,1,2).to_s, t.due.to_s
  end
  
  def test_mobile_create_action_redirects_to_mobile_home_page_when_successful
    login_as(:admin_user)
    post :create, {"format"=>"m", "todo"=>{"context_id"=>"2",
        "due(1i)"=>"2007", "due(2i)"=>"1", "due(3i)"=>"2",
        "show_from(1i)"=>"", "show_from(2i)"=>"", "show_from(3i)"=>"",
        "project_id"=>"1", 
        "notes"=>"test notes", "description"=>"test_mobile_create_action", "state"=>"0"}}
    assert_redirected_to '/m'
  end

  def test_mobile_create_action_renders_new_template_when_save_fails
    login_as(:admin_user)
    post :create, {"format"=>"m", "todo"=>{"context_id"=>"2",
        "due(1i)"=>"2007", "due(2i)"=>"1", "due(3i)"=>"2",
        "show_from(1i)"=>"", "show_from(2i)"=>"", "show_from(3i)"=>"",
        "project_id"=>"1", 
        "notes"=>"test notes", "state"=>"0"}, "tag_list"=>"test, test2"}
    assert_template 'todos/new'
  end

  def test_index_html_assigns_default_project_name_map
    login_as(:admin_user)
    get :index, {"format"=>"html"}
    assert_equal '"{\\"Build a working time machine\\": \\"lab\\"}"', assigns(:default_project_context_name_map)
  end

  def test_toggle_check_on_recurring_todo
    login_as(:admin_user)
    
    # link todo_1 and recurring_todo_1
    recurring_todo_1 = RecurringTodo.find(1)
    todo_1 = Todo.find(1)
    todo_1.recurring_todo_id = recurring_todo_1.id
    
    # update todo_1
    assert todo_1.save
    
    # mark todo_1 as complete by toggle_check
    xhr :post, :toggle_check, :id => 1, :_source_view => 'todo' 
    todo_1.reload
    assert todo_1.completed?

    # check there is a new todo linked to the recurring pattern
    next_todo = Todo.find_by_recurring_todo_id(recurring_todo_1.id)
    assert_equal "Call Bill Gates every day", next_todo.description
  end
  
end
