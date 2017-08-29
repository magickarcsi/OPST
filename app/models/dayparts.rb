class Dayparts
  include Mongoid::Document
  field :storeId, type: String
  field :daypart_num, type: Integer
  field :start, type: Integer
  field :finish, type: Integer
  field :open, type: Boolean, default: true
end