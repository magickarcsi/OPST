class DtsHourly
  include Mongoid::Document
  field :date, :type => DateTime
  field :datestring, type: String
  field :hour, type: String
  field :cars, type: String
  field :COD1, type: String
  field :COD2, type: String
  field :Cashier, type: String
  field :Presenter, type: String
  field :OEPE, type: String
  field :AST, type: String
  field :TAR_COD1, type: String
  field :TAR_COD2, type: String
  field :TAR_Cashier, type: String
  field :TAR_Presenter, type: String
  field :TAR_OEPE, type: String
  field :TAR_AST, type: String
end
