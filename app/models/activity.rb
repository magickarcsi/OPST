class Activity
  include Mongoid::Document
  field :uid, type: String
  field :event, type: String
  field :storeId, type: String
  field :timestamp, :type => DateTime
end