require 'io/console'
require 'socket'
require 'json'
require 'tty-cursor'
require 'tty-screen'

class Client
  def initialize (server)
    @server = server
    @request = nil
    @response = nil
    @cursor = TTY::Cursor
    @size = TTY::Screen.size # => [height, width]
    @height = @size[0]
    @width = @size[1]
    @len = 1
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
      # puts; puts response[:message]
      print @cursor.move_to(0, 0)
      puts response[:message]
      break if response[:ok]
    end
  end

  def listen
    @response = Thread.new do
      loop {
        msg = @server.gets.chomp
        print @cursor.move_to(0, @len)
        @len += 1
        puts "#{msg}"
        print @cursor.move_to(0, @height)
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
