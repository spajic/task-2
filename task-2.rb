# Deoptimized version of homework task

require 'json'
require 'pry'
require 'date'
require 'ruby-progressbar'

IE_REGEX = /INTERNET EXPLORER/i.freeze
NOT_CHROME_REGEX = /(?<!chrome)\s\d+/i.freeze
SESSION_PREF = 'session,'
USER_PREF = 'user,'

class User
  attr_reader :attributes, :sessions

  def initialize(attributes:, sessions:)
    @attributes = attributes
    @sessions = sessions
  end
end

def parse_user(fields)
  {
    id: fields[0],
    first_name: fields[1],
    last_name: fields[2],
    age: fields[3]
  }
end

def parse_session(fields)
  {
    user_id: fields[0],
    session_id: fields[1],
    browser: fields[2],
    time: fields[3],
    date: fields[4]
  }
end

def work(file_name = 'data.txt')
  # total_lines = %x[cat #{file_name} | wc -l].to_i
  # progressbar = ProgressBar.create(title: 'Parse file', total: total_lines, format: '%a |%b>>%i| %p%% %t')

  file_lines = File.read(file_name).split("\n")

  users = []
  sessions = []
  grouped_sessions = {}

  File.open(file_name, 'r').each do |line|
    if line.start_with?('user')
      line[USER_PREF] = ''
      cols = line.split(',')
      users << parse_user(cols)
    else
      line[SESSION_PREF] = ''
      cols = line.split(',')
      session = parse_session(cols)
      sessions << session
      grouped_sessions[session[:user_id]] ||= []
      grouped_sessions[session[:user_id]] << session
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

  report = {}

  report[:totalUsers] = users.count

  # Подсчёт количества уникальных браузеров
  uniqueBrowsers = []

  sessions.each do |session|
    browser = session[:browser]
    uniqueBrowsers << browser unless uniqueBrowsers.include?(browser)
  end

  report[:uniqueBrowsersCount] = uniqueBrowsers.count

  report[:totalSessions] = sessions.count

  report[:allBrowsers] =
    sessions
      .map { |s| s[:browser] }
      .map { |b| b.upcase }
      .sort
      .uniq
      .join(',')

  # Статистика по пользователям
  users_objects = []

  users.each do |user|
    attributes = user
    user_sessions = grouped_sessions[user[:id]]
    user_object = User.new(attributes: attributes, sessions: user_sessions)
    users_objects = users_objects + [user_object]
  end

  report[:usersStats] = users_objects.each.with_object({}) do |user, hash|
    user_key = "#{user.attributes[:first_name]} #{user.attributes[:last_name]}"

    longest_session = user.sessions.max { |a,b| a[:time].to_i <=> b[:time].to_i }
    user_browsers   = user.sessions.map {|s| s[:browser].upcase }.sort.join(', ')

    hash[user_key] = {
      # Собираем количество сессий по пользователям
      sessionsCount: user.sessions.count,
      # Собираем количество времени по пользователям
      totalTime: "#{user.sessions.sum { |s| s[:time].to_i }} min.",
      # Выбираем самую длинную сессию пользователя
      longestSession: "#{longest_session[:time]} min.",
      # Браузеры пользователя через запятую
      browsers: user_browsers,
      # Хоть раз использовал IE?
      usedIE: user_browsers.match?(IE_REGEX),
      # Всегда использовал только Chrome?
      alwaysUsedChrome: !user_browsers.match?(NOT_CHROME_REGEX),
      # Даты сессий через запятую в обратном порядке в формате iso8601
      dates: user.sessions.map { |s| Date.iso8601(s[:date]) }.sort.reverse_each.with_object([]) { |d, arr| arr << d }
    }
  end

  File.write('result.json', "#{report.to_json}\n")
end
