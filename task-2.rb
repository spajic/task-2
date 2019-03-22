# Deoptimized version of homework task

require 'oj'
require 'pry'
require 'date'
require 'progress_bar'

IE = 'INTERNET EXPLORER'.freeze
CHROME = 'CHROME'.freeze
SESSION = 'session'.freeze
USER = 'user'.freeze
COMMA = ','.freeze
DATE_FORMAT = '%Y-%m-%d'.freeze
MIN = ' min.'.freeze
class User
  attr_reader :attributes, :sessions

  def initialize(attributes:, sessions:)
    @attributes = attributes
    @sessions = sessions
  end
end

def parse_user(fields)
  {
    'id' => fields[1],
    'first_name' => fields[2],
    'last_name' => fields[3],
    'age' => fields[4],
  }
end

def parse_session(fields)
  {
    'user_id' => fields[1],
    'session_id' => fields[2],
    'browser' => fields[3].upcase!,
    'time' => fields[4].to_i,
    'date' => fields[5],
  }
end

def collect_stats_from_users(report, users_objects, &block)
  while(users_objects.size > 0) do
    user = users_objects.shift
    user_key = user.attributes['first_name'] << " " << user.attributes['last_name']
    report['usersStats'][user_key] ||= {}
    report['usersStats'][user_key].merge!(block.call(user))
  end
end

def always_used_chrome?(*browsers)
  browsers.delete_if { |browser| browser.start_with?(CHROME) }
  browsers.empty?
end

def file_processing(file, users, sessions)
  file = File.open(file)

  file.each_line do |line|
    line = line.split(COMMA)
    users << parse_user(line) if line[0] == USER
    sessions[line[1]] << parse_session(line) if line[0] == SESSION
  end

  file.close
end

def sessions_processing(sessions, report)
  # Подсчёт количества уникальных браузеров
  allBrowsers = []

  sessions_count = 0
  sessions.values.flatten!.each do |session|
    sessions_count += 1
    browser = session['browser']
    allBrowsers << browser
  end
  allBrowsers.sort!.uniq!

  report['uniqueBrowsersCount'] = allBrowsers.count
  report['totalSessions'] = sessions_count
  report['allBrowsers'] = allBrowsers.join(COMMA)
end

def work(file = 'data/data_large.txt', progress: false)
  users = []
  sessions = Hash.new { |hash, key| hash[key] = [] }

  file_processing(file, users, sessions)
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
  report['totalUsers'] = users.count

  sessions_processing(sessions, report)

  # Статистика по пользователям
  users.map! do |user|
    user_sessions = sessions[user['id']]
    User.new(attributes: user, sessions: user_sessions)
  end

  report['usersStats'] = {}
  bar = ProgressBar.new(users.size)

  # Собираем количество сессий по пользователям
  # Собираем количество времени по пользователям
  # Выбираем самую длинную сессию пользователя
  # Браузеры пользователя через запятую
  # Хоть раз использовал IE?
  # Всегда использовал только Chrome?
  # Даты сессий через запятую в обратном порядке в формате iso8601
  collect_stats_from_users(report, users) do |user|
    times = user.sessions.map { |s| s['time'] }
    browsers = user.sessions.map { |s| s['browser'] }
    bar.increment! if progress
    {
      'sessionsCount' => user.sessions.count,
      'totalTime' => times.sum.to_s << MIN,
      'longestSession' => times.max.to_s << MIN,
      'browsers' => browsers.sort!.join(COMMA + " "),
      'usedIE' => browsers.any? { |b| b.start_with?(IE) },
      'alwaysUsedChrome' => always_used_chrome?(*browsers),
      'dates' => user.sessions.map! { |s| Date.strptime(s['date'], DATE_FORMAT).iso8601 }.sort!.reverse!
    }
  end

  File.write('result.json', Oj.dump(report, mode: :compat) << "\n")
end

work