module ActiveModel
  class Serializer
    class CollectionSerializer
      NoSerializerError = Class.new(StandardError)
      include Enumerable
      delegate :each, to: :@serializers

      attr_reader :object, :root

      def initialize(resources, options = {})
        @object                  = resources
        @options                 = options
        @root                    = options[:root]
        serializer_context_class = options.fetch(:serializer_context_class, ActiveModel::Serializer)
        @serializers = resources.map do |resource|
          serializer_class = options.fetch(:serializer) { serializer_context_class.serializer_for(resource) }

          if serializer_class.nil? # rubocop:disable Style/GuardClause
            fail NoSerializerError, "No serializer found for resource: #{resource.inspect}"
          else
            serializer_class.new(resource, options.except(:serializer))
          end
        end
      end

      def success?
        true
      end

      # TODO: unify naming of root, json_key, and _type.  Right now, a serializer's
      # json_key comes from the root option or the object's model name, by default.
      # But, if a dev defines a custom `json_key` method with an explicit value,
      # we have no simple way to know that it is safe to call that instance method.
      # (which is really a class property at this point, anyhow).
      # rubocop:disable Metrics/CyclomaticComplexity
      # Disabling cop since it's good to highlight the complexity of this method by
      # including all the logic right here.
      def json_key
        return root if root
        # 1. get from options[:serializer] for empty resource collection
        key = object.empty? &&
          (explicit_serializer_class = options[:serializer]) &&
          explicit_serializer_class._type
        # 2. get from first serializer instance in collection
        key ||= (serializer = serializers.first) && serializer.json_key
        # 3. get from collection name, if a named collection
        key ||= object.respond_to?(:name) ? object.name && object.name.underscore : nil
        # 4. key may be nil for empty collection and no serializer option
        key && key.pluralize
      end
      # rubocop:enable Metrics/CyclomaticComplexity

      def paginated?
        object.respond_to?(:current_page) &&
          object.respond_to?(:total_pages) &&
          object.respond_to?(:size)
      end

      protected

      attr_reader :serializers, :options
    end
  end
end
