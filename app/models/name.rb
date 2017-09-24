class Name
  include Mongoid::Document
  
  validates :firstname, presence: true,
                        length: { maximum: 50 }
  validates :lastname, presence: true,
                        length: { maximum: 50 }
  
  field :id, type: String
  field :firstname, type: String
  field :lastname, type: String
  field :store, type: String
  field :personId, type: String
  field :nameid, type: Integer
  field :active, type: Mongoid::Boolean
  
end
