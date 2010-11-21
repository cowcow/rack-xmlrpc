
require 'rack'
require 'rack/showexceptions'
require "./rack-xmlrpc"

s = Rack::XMLRPC.new
s.add_handler("xmlrpc") { |a,b|
	a + b
}

run( s )
