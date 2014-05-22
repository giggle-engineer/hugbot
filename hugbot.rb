require 'cinch'
require 'sqlite3'

databaseExists = File.exist?("hugs.db")

db = SQLite3::Database.new "hugs.db"

if not databaseExists
    rows = db.execute <<-SQLite3
    CREATE TABLE users (
        user text primary key,
        nick text,
        hugcount integer
    );
    SQLite3
end

bot = Cinch::Bot.new do
  configure do |c|
  	c.nick = "hugbot"
  	c.name = "hugbot"
    c.server = "irc.unstable.systems"
    c.channels = ["#chat"]
  end

  # Hug Detection

  on :message, /(hugs).*?((?:[a-z][a-z]+))/ do |m|
  	isUserNew = 0
  	db.execute("SELECT * FROM users WHERE user='#{m.user.user}'") do |row|
        isUserNew = 1
    end
    if isUserNew==0
        db.execute("INSERT INTO users VALUES ('#{m.user.user}', '#{m.user.nick}', 0)")
    end
    db.execute("UPDATE users SET hugcount = hugcount+1 WHERE user = '#{m.user.user}'")
    db.execute("UPDATE users SET nick = '#{m.user.nick}' WHERE user = '#{m.user.user}'")
  end

  # Hugging Back

  on :message, /(hugs).*?(hugbot)/ do |m|
  	m.action_reply "hugs #{m.user.nick}"
  end

  # Commands

  on :message, /(@)(hugcount)/ do |m|
  	db.execute("SELECT * FROM users ORDER BY hugcount") do |user|
        m.reply "#{user[1]}:#{user[2]}"
    end
  end
end

bot.start