class Thought < ActiveRecord::Base
	belongs_to :user
	attr_protected :user
	
	validates_presence_of :body, :message => "thought must have a body"

	acts_as_list :scope => 'user_id = #{user_id}'
end
