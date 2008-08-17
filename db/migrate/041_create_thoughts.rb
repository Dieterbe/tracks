class CreateThoughts < ActiveRecord::Migration
  def self.up
   create_table :thoughts do |t|
      t.column :user_id,        :integer,    :null => false
      t.column :body,           :text,       :null => false
      t.column :created_at,     :timestamp
      t.column :updated_at,     :timestamp
    end
  
  add_index :thoughts, :user_id
  end

  def self.down
    remove_index :thoughts, :user_id
    drop_table :thoughts
  end
end
