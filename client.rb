require "io/console"
require "socket"
require "json"
require "tty-cursor"
require "tty-screen"

class TTYChat
  def initialize
    @cursor = TTY::Cursor
    (@height, @width) = TTY::Screen.size
    @buffer = []
    @len = 0
    print @cursor.clear_screen
    print @cursor.move_to(0, @height - 1)
    print ">> "
  end

  def puts(message)
    print @cursor.save
    if @len == @height - 2
      @buffer.shift
      @buffer.push message
      print @cursor.move_to(0, 0)
      @buffer.each do |msg|
        print @cursor.clear_line
        print msg
        print @cursor.down
      end
    else
      print @cursor.move_to(0, @len)
      @len += 1
      @buffer.push message
      STDOUT.puts message
    end
    print @cursor.restore
  end

  def scroll_up
    print @cursor.scroll_up
  end

  def clear_line
    print @cursor.clear_line
  end
end

class Client
  def initialize(server)
    @server = server
    @request = nil
    @response = nil
    @tty = nil
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
      if response[:ok]
        @tty = TTYChat.new
        @tty.puts response[:message]
        break
      else
        puts response[:message]
      end
    end
  end

  def listen
    @response = Thread.new do
      loop {
        msg = @server.gets.chomp
        @tty.puts msg
      }
    end
  end

  def send
    @request = Thread.new do
      loop {
        msg = $stdin.gets.chomp
        @server.puts(msg)
        @tty.scroll_up
        @tty.puts "-: #{msg}"
        @tty.clear_line
        print ">> "
      }
    end
  end
end

server = TCPSocket.open("localhost", 2015)
Client.new(server)
