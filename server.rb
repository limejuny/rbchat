require 'io/console'
require 'socket'
require 'redis'
require 'json'

class Server
  def initialize (ip, port)
    @server = TCPServer.open( ip, port )
    @connections = Hash.new
    @clients = Hash.new
    @redis = Redis.new
    @connections[:server] = @server
    @connections[:clients] = @clients
    run
  end

  def run
    loop {
      Thread.start(@server.accept) do | client |
        #         nick_name = client.gets.chomp.to_sym
        #         @connections[:clients].each do |other_name, other_client|
        #           if nick_name == other_name || client == other_client
        #             client.puts "This username already exist"
        #             Thread.kill self
        #           end
        #         end
        #         puts "#{nick_name} #{client}"
        #         @connections[:clients][nick_name] = client
        id = idcheck(client)
        client.puts "Connection established, Thank you for joining! Happy chatting"
        listen_user_messages( nick_name, client )
      end
    }.join
  end

  def idcheck (client)
    (id, pwd) = JSON.parse(client.gets).values
    # check id, pwd in redis
    return id.to_sym
  end

  def listen_user_messages (username, client)
    loop {
      msg = client.gets.chomp
      @connections[:clients].each do |other_name, other_client|
        unless other_name == username
          other_client.puts "#{username.to_s}: #{msg}"
        end
      end
    }
  end
end

Server.new("localhost", 2015)
