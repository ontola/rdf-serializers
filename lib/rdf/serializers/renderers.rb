# frozen_string_literal: true

# Registers the N-Triples renderer
#
# And then in controllers, use `render nt: model`.
#
# For example, in a controller action, we can:
# respond_to do |format|
#   format.nt { render nt: model }
# end

module RDF
  module Serializers
    module Renderers
      def self.register(symbols, opts = {})
        symbols = [symbols] unless symbols.respond_to?(:each)
        symbols.each do |symbol|
          format = RDF::Format.for(symbol)
          raise "#{symbol} is not a known rdf format" if format.nil?

          Mime::Type.register format.content_type.first, format.file_extension.first
          add_renderer(format.file_extension.first, format.content_type.first, format.symbols.first, opts)
        end
      end

      def self.add_renderer(ext, content_type, symbol, opts = {})
        ActionController::Renderers.add ext do |resource, options|
          self.content_type = content_type
          serializer_opts = RDF::Serializers::Renderers.transform_opts(
            options,
            respond_to?(:serializer_params, true) ? serializer_params : {}
          )
          RDF::Serializers.serializer_for(resource)&.new(resource, serializer_opts)&.dump(symbol, **opts)
        end
      end

      def self.transform_include(include, root = nil)
        return root if include.blank?
        return [root, [root, include].compact.join('.')] if include.is_a?(Symbol) || include.is_a?(String)

        if include.is_a?(Hash)
          include.flat_map do |k, v|
            transform_include(v, [root, k].compact.join('.'))
          end
        elsif include.is_a?(Array)
          include.flat_map do |v|
            transform_include(v, root)
          end
        end.compact.uniq
      end

      def self.transform_opts(options, params)
        (options || {}).merge(
          include: transform_include(options[:include]),
          params: params
        )
      end
    end
  end
end
