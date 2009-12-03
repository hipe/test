class Service < Sequel::Model
  set_schema do
    primary_key :id
    
    varchar :name, :unique => true, :empty => false
    boolean :checked, :default => false
  end
  
  create_table unless table_exists?
  
  if empty?
    create :name => 'tumblr'
    create :name => 'wordpress'
  end
  
end