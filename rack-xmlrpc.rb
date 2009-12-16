
require 'xmlrpc/server'
require 'rack/request'
require 'rack/response'

module Rack
	class XMLRPC < XMLRPC::BasicServer

		class XMLRPCError < StandardError
			attr_reader :status
			attr_reader :message

			def initialize( status, message )
				super()
				@status = status
				@message = message
			end
		end

		def call(env)
			req = Request.new(env)
			res = Response.new()
			res['Content-Type'] = 'text/xml; charset=utf-8'

			unless( req.post? )
				raise XMLRPCError.new( 405, "Method Not Allowed" )
			end

			unless( parse_content_type(req.content_type).first == "text/xml" )
				raise XMLRPCError.new( 400, "Bad Request" )
			end

			length = req.content_length().to_i

			unless( length > 0 )
				raise XMLRPCError.new( 411, "Length Required" )
			end

			data = req.env["rack.input"].read

			if( data.nil? or data.size != length )
				raise XMLRPCError.new( 400, "Bad Request" )
			end

			res.write( process( data ) )
			res.finish
		rescue XMLRPCError => e
			res.status = e.status
			res.write( http_error( e.status, e.message ) )
			res.finish
		end

		def http_error( status, message )
			err = "#{status} #{message}"
			msg = <<-"MSGEND"
			<html>
			<head>
				<title>#{err}</title>
			</head>
			<body>
				<h1>#{err}</h1>
				<p>Unexpected error occured while processing XML-RPC request!</p>
			</body>
			</html>
			MSGEND
		end

	end
end

if $0 == __FILE__
	require 'rack'
	require 'rack/showexceptions'

	s = Rack::XMLRPC.new
	s.add_handler("xmlrpc") { |a,b|
		a + b
	}

	Rack::Handler::WEBrick.run(
		Rack::ShowExceptions.new(
			Rack::Lint.new( s )
		),
		:Port => 9292 )
end
