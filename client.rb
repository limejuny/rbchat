require 'io/console'
require 'socket'
require 'json'

class Client
  def initialize (server)
    @server = server
    @request = nil
    @response = nil
    login
    listen
    send
    @request.join
    @response.join
  end

  def login
    loop do
      print "Enter the username: "
      id = gets.chomp
      print "Enter the password: "
      pwd = $stdin.noecho(&:gets).chomp
      @server.puts({
        id: id,
        pwd: pwd,
      }.to_json)
      response = JSON.parse(@server.gets, symbolize_names: true)
      puts; puts response[:message]
      break if response[:ok]
    end
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
