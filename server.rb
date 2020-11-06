require "io/console"
require "socket"
require "json"
require "redis"

class Server
  def initialize(ip, port)
    @server = TCPServer.open(ip, port)
    @clients = Hash.new
    @redis = Redis.new
    run
  end

  def run
    loop {
      Thread.start(@server.accept) do |client|
        (id, idx) = idcheck client
        puts "#{id} #{client}"
        @clients[id] = client
        listen_user_messages(id, client, idx)
      end
    }.join
  end

  def idcheck(client)
    loop do
      (id, pwd) = JSON.parse(client.gets).values

      if ["bit_login", "bit_index"].include? id
        client.puts({ message: "Cannot use #{id} as id.", ok: false }.to_json)
        next
      end

      unless @redis.exists? id
        index = @redis.bitcount(:bit_index)
        @redis.hset(id, :pwd, pwd, :index, index)
        @redis.setbit(:bit_index, index, 1)
        @redis.setbit(:bit_login, index, 1)
        client.puts({ message: "로그인 성공.", ok: true }.to_json)
        return [id.to_sym, index]
      end

      unless @redis.hget(id, :pwd) == pwd
        client.puts({ message: "비밀번호가 틀렸습니다. 다시 시도해 주세요.", ok: false }.to_json)
        next
      end

      index = @redis.hget(id, :index)
      if @redis.getbit(:bit_login, index) == 1
        client.puts({ message: "현재 접속중인 아이디입니다.", ok: false }.to_json)
        next
      end

      @redis.setbit(:bit_login, index, 1)
      client.puts({ message: "로그인 성공.", ok: true }.to_json)
      return [id.to_sym, index]
    end
  end

  def listen_user_messages(id, client, idx)
    loop {
      msg = client.gets
      if msg.nil?
        client.close
        @redis.setbit(:bit_login, idx, 0)
        @clients.delete(id)
      else
        msg = msg.chomp
        @clients.each do |other_name, other_client|
          unless other_name == id
            other_client.puts "#{id.to_s}: #{msg}"
          end
        end
      end
    }
  end
end

Server.new("localhost", 2015)
