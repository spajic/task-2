# frozen_string_literal: true

require 'json'
require 'pry'
require 'date'

class User
  attr_reader :attributes, :sessions, :browsers, :time

  def initialize(attributes:, sessions:)
    @attributes = attributes
    @sessions = sessions
    @browsers = sessions.map { |s| s[:browser] }.map!(&:upcase).sort!
    @time = sessions.map { |s| s[:time] }.map!(&:to_i)
  end

  def stats
    {
      sessionsCount: sessions.count,
      totalTime: "#{time.sum} min.",
      longestSession: "#{time.max} min.",
      browsers: browsers.join(', '),
      usedIE: browsers.any? { |b| b =~ /INTERNET EXPLORER/ },
      alwaysUsedChrome: browsers.uniq.all? { |b| b =~ /CHROME/ },
      dates: sessions.map { |s| s[:date] }.map! { |d| Date.iso8601(d) }.sort! { |x, y| y <=> x }
    }
  end
end

def parse_user(user)
  {
    id: user[1],
    first_name: user[2],
    last_name: user[3],
    age: user[4]
  }
end

def parse_session(session)
  {
    user_id: session[1],
    session_id: session[2],
    browser: session[3],
    time: session[4],
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
  file_lines = File.read(file_name).split("\n")

  users = {}
  sessions = {}

  file_lines.each do |line|
    cols = line.split(',')
    users[cols[1]] = parse_user(cols) if cols[0] == 'user'

    next unless cols[0] == 'session'

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
  report['allBrowsers'] = unique_browsers.map!(&:upcase).sort!.join(',')
  report['usersStats'] = {}

  # Статистика по пользователям
  users_objects = users.each.with_object([]) do |(user_id, attrs), arr|
    arr << User.new(attributes: attrs, sessions: sessions[user_id])
  end

  collect_stats_from_users(report, users_objects)

  File.open('result.json', 'w') do |file|
    file.write(report.to_json)
    file.write("\n")
  end
end
