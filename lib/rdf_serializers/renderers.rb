# frozen_string_literal: true

# Registers the N-Triples renderer
#
# And then in controllers, use `render nt: model`.
#
# For example, in a controller action, we can:
# respond_to do |format|
#   format.nt { render nt: model }
# end

require 'active_model_serializers/adapter/rdf.rb'

module RDFSerializers
  module Renderers
    def self.register(symbols, opts = {})
      symbols = [symbols] unless symbols.respond_to?(:each)
      symbols.each do |symbol|
        format = RDF::Format.for(symbol)
        raise "#{symbol} if not a known rdf format" if format.nil?
        Mime::Type.register format.content_type.first, format.file_extension.first
        add_renderer(format, opts)
      end
    end

    def self.add_renderer(format, opts = {})
      ActionController::Renderers.add format.file_extension.first do |resource, options|
        self.content_type = format.content_type.first
        get_serializer(resource, options.merge(adapter: :rdf)).adapter.dump(format.symbols.first, opts)
      end
    end
  end
end
