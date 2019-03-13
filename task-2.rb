# frozen_string_literal: true

require 'pry'
require 'date'
require 'oj'
require 'ruby-progressbar'
require 'set'

IE = /INTERNET EXPLORER/.freeze
CHROME = /CHROME/.freeze
USER = 'user'.freeze
SESSION = 'session'.freeze
COMMA = ','.freeze

class User
  attr_reader :sessions, :browsers, :time, :key

  def initialize(attributes:, sessions:)
    @key = "#{attributes[:first_name]} #{attributes[:last_name]}"
    @sessions = sessions
    @browsers = sessions.map { |s| s[:browser] }.sort! { |x, y| x <=> y }
    @time = sessions.map { |s| s[:time] }
  end

  def stats
    {
      sessionsCount: sessions.length,
      totalTime: "#{time.sum} min.",
      longestSession: "#{time.max} min.",
      browsers: browsers.join(', '),
      usedIE: browsers.any? { |b| b.match?(IE) },
      alwaysUsedChrome: browsers.uniq.all? { |b| b.match?(CHROME) },
      dates: sessions.map { |s| s[:date] }.sort! { |x, y| y <=> x }
    }
  end
end

def parse_user(users, fields)
  users[fields[1].to_i] = {
    first_name: fields[2],
    last_name: fields[3],
    age: fields[4]
  }
  users
end

def parse_session(sessions, fields)
  id = fields[1].to_i
  sessions[id] ||= []
  sessions[id] << {
    session_id: fields[2],
    browser: fields[3].upcase!,
    time: fields[4].to_i,
    date: fields[5]
  }
  sessions
end

def work(file_name)
  # GC.disable
  file_lines = File.read(file_name).split("\n")

  # progressbar = ProgressBar.create(total: file_lines.count, format: '%a, %J, %E %B')

  users = {}
  sessions = {}
  file_lines.each do |line|
    # progressbar.increment
    cols = line.split(COMMA)

    case cols[0]
    when USER
      parse_user(users, cols)
    when SESSION
      parse_session(sessions, cols)
    end
  end

  # Отчёт в json
  #   - Сколько всего юзеров +
  #   - Сколько всего уникальных браузеров +
  #   - Сколько всего сессий +
  #   - Перечислить уникальные браузеры в алфавитном порядке через запятую и капсом +
  #
  #   - По каждому пользователю
  #     - сколько всего сессий +
  #     - сколько всего времени +
  #     - самая длинная сессия +
  #     - браузеры через запятую +
  #     - Хоть раз использовал IE? +
  #     - Всегда использовал только Хром? +
  #     - даты сессий в порядке убывания через запятую +

  all_sessions = sessions.values.flatten

  # Подсчёт количества уникальных браузеров
  unique_browsers = all_sessions.map { |s| s[:browser] }.uniq!

  report = {}
  report['totalUsers'] = users.keys.length
  report['uniqueBrowsersCount'] = unique_browsers.length
  report['totalSessions'] = all_sessions.length
  report['allBrowsers'] = unique_browsers.sort! { |x, y| x <=> y }.join(COMMA)
  report['usersStats'] = {}

  users.each do |user_id, attrs|
    user = User.new(attributes: attrs, sessions: sessions[user_id])
    report['usersStats'][user.key] ||= {}
    report['usersStats'][user.key] = user.stats
  end

  File.open('result.json', 'w') do |file|
    file.write(Oj.dump(report, mode: :compat))
    file.write("\n")
  end
end
