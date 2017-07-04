module Columns
    extend ActiveSupport::Concern

    def self.included(base)
        base.extend ClassMethods
    end

    module ClassMethods

        def columns
            ary = []
            excluded_column_names = %w[id created_at updated_at _id _type created_at]
            self.fields.collect{|c| c[1]}.reject{|c| excluded_column_names.include?(c.name) }.each do |c|
                ary.append(MongoDBColumn.new(:name => c.name, :type => c.type.to_s.downcase)) unless c.nil?
            end
            return ary
        end
    end
end