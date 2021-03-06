class DtsDaily
  include Mongoid::Document
  field :date, :type => DateTime
  field :datestring, type: String
  field :COD1, type: Integer
  field :COD2, type: Integer
  field :HHOT, type: Integer
  field :Cashier, type: Integer
  field :Presenter, type: Integer
  field :OEPE, type: Integer
  field :AST, type: Integer
  field :TAR_COD1, type: Integer
  field :TAR_COD2, type: Integer
  field :TAR_HHOT, type: Integer
  field :TAR_Cashier, type: Integer
  field :TAR_Presenter, type: Integer
  field :TAR_OEPE, type: Integer
  field :TAR_AST, type: Integer
  field :storeId, type: String
end