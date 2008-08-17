require File.dirname(__FILE__) + '/../test_helper'

class ThoughtsControllerTest < ActionController::TestCase
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:thoughts)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_thought
    assert_difference('Thought.count') do
      post :create, :thought => { }
    end

    assert_redirected_to thought_path(assigns(:thought))
  end

  def test_should_show_thought
    get :show, :id => thoughts(:one).id
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => thoughts(:one).id
    assert_response :success
  end

  def test_should_update_thought
    put :update, :id => thoughts(:one).id, :thought => { }
    assert_redirected_to thought_path(assigns(:thought))
  end

  def test_should_destroy_thought
    assert_difference('Thought.count', -1) do
      delete :destroy, :id => thoughts(:one).id
    end

    assert_redirected_to thoughts_path
  end
end
