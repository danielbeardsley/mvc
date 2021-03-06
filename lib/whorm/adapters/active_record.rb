##
# ActiveRecord adapter to Whorm::Model mixin.
#
module Whorm
  module Model
    module ClassMethods
      def whorm_primary_key
        self.primary_key.to_sym
      end
      
      def whorm_column_names
        self.column_names.map(&:to_sym)
      end
      
      def whorm_columns_hash
        self.columns_hash.symbolize_keys
      end
      
      ##
      # determine if supplied Column object is nullable
      # @param {ActiveRecord::ConnectionAdapters::Column}
      # @return {Boolean}
      #
      def whorm_allow_blank(col)
        # if the column is the primary key always allow it to be blank.
        # Otherwise we could not create new records with whorm because
        # new records have no id and thus cannot be valid
        col.name == self.primary_key || col.null
      end
      
      ##
      # returns the default value
      # @param {ActiveRecord::ConnectionAdapters::Column}
      # @return {Mixed}
      #
      def whorm_default(col)
        col.default
      end
      
      ##
      # returns the corresponding column name of the type column for a polymorphic association
      # @param {String/Symbol} the id column name for this association
      # @return {Symbol}
      def whorm_polymorphic_type(id_column_name)
        id_column_name.to_s.gsub(/_id\Z/, '_type').to_sym
      end
      
      ##
      # determine datatype of supplied Column object
      # @param {ActiveRecord::ConnectionAdapters::Column}
      # @return {String}
      #
      def whorm_type(col)
        type = col.type.to_s
        case type
          when "datetime", "date", "time", "timestamp"
            type = "date"
          when "text"
            type = "string"
          when "integer"
            type = "int"
          when "decimal"
            type = "float"
        end
        type
      end
      
      ##
      # return a simple, normalized list of AR associations having the :name, :type and association class
      # @return {Array}
      #
      def whorm_associations
        @whorm_associations ||= self.reflections.inject({}) do |memo, (key, assn)|
          type = (assn.macro === :has_many || assn.macro === :has_and_belongs_to_many) ? :many : assn.macro
          memo[key.to_sym] = {
            :name => key.to_sym, 
            :type => type, 
            :class => assn.options[:polymorphic] ? nil : assn.class_name.constantize,
            :foreign_key => assn.association_foreign_key.to_sym,
            :is_polymorphic => !!assn.options[:polymorphic]
          }
          memo
        end
      end
    end
  end
end

