require 'io/console'
require 'socket'
require 'json'

class Client
  def initialize (server)
    @server = server
    @request = nil
    @response = nil
    listen
    signin
    send
    @request.join
    @response.join
  end

  def signin
    print "Enter the username: "
    id = $stdin.gets.chomp
    print "Enter the password: "
    pwd = STDIN.noecho(&:gets).chomp
    @server.puts({
      id: id,
      pwd: pwd,
    }.to_json)
    # id check
  end

  def listen
    @response = Thread.new do
      loop {
        msg = @server.gets.chomp
        puts "#{msg}"
      }
    end
  end

  def send
    @request = Thread.new do
      loop {
        msg = $stdin.gets.chomp
        @server.puts( msg )
      }
    end
  end
end

server = TCPSocket.open("localhost", 2015)
Client.new(server)
