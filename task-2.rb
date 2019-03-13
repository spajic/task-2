# frozen_string_literal: true

# require 'json'
require 'pry'
require 'date'
require 'oj'
require 'ruby-progressbar'

IE = /INTERNET EXPLORER/.freeze
CHROME = /CHROME/.freeze
USER = 'user'.freeze
SESSION = 'session'.freeze
COMMA = ','.freeze

class User
  attr_reader :attributes, :sessions, :browsers, :time

  def initialize(attributes:, sessions:)
    @attributes = attributes
    @sessions = sessions
    @browsers = sessions.map { |s| s[:browser] }.sort! { |x, y| x <=> y }
    @time = sessions.map { |s| s[:time] }
  end

  def stats
    {
      sessionsCount: sessions.count,
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
  users[fields[1]] = {
    first_name: fields[2],
    last_name: fields[3],
    age: fields[4]
  }
  users
end

def parse_session(session)
  {
    user_id: session[1],
    session_id: session[2],
    browser: session[3].upcase!,
    time: session[4].to_i,
    date: session[5]
  }
end

def collect_stats_from_users(report, users_objects)
  users_objects.each do |user|
    user_key = "#{user.attributes[:first_name]} #{user.attributes[:last_name]}"
    report['usersStats'][user_key] ||= {}
    report['usersStats'][user_key] = user.stats
  end
end

def work(file_name)
  GC.disable
  # IO.foreach()
  file_lines = File.read(file_name).split("\n")

  # progressbar = ProgressBar.create(total: file_lines.count, format: '%a, %J, %E %B')

  users = {}
  sessions = {}
  # IO.foreach(file_name)
  # File.read(file_name).each_line do |line|
  file_lines.each do |line|
    # binding.pry
    # progressbar.increment

    # line.start_with?(USER)

    cols = line.split(COMMA)
    # users[cols[1]] = parse_user(cols) if line.start_with?(USER) # if cols[0] == 'user'
    # line.start_with?(USER)
    # binding.pry
    parse_user(users, cols) if cols[0].start_with?(USER)
    # binding.pry
    # next unless cols[0] == 'session'
    next unless cols[0].start_with?(SESSION)

    id = cols[1]
    sessions[id] ||= []
    sessions[id] << parse_session(cols)
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
  report['totalUsers'] = users.keys.count
  report['uniqueBrowsersCount'] = unique_browsers.count
  report['totalSessions'] = all_sessions.count
  report['allBrowsers'] = unique_browsers.sort! { |x, y| x <=> y }.join(COMMA)
  report['usersStats'] = {}

  # Статистика по пользователям
  users_objects = users.each.with_object([]) do |(user_id, attrs), arr|
    arr << User.new(attributes: attrs, sessions: sessions[user_id])
  end

  collect_stats_from_users(report, users_objects)

  File.open('result.json', 'w') do |file|
    # file.write(report.to_json)
    # binding.pry
    file.write(Oj.dump(report, mode: :compat))
    file.write("\n")
  end
end
