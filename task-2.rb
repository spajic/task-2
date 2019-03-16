# rubocop:disable all
# Deoptimized version of homework task

require 'json'
require 'pry'
require 'date'
require 'ruby-progressbar'

class User
  attr_reader :attributes, :sessions, :id, :full_name

  def initialize(attributes:, sessions:, id:, full_name:)
    @attributes = attributes
    @sessions = sessions
    @id = id
    @full_name = full_name
  end
end

def parse_user(user)
  fields = user.split(',')
  parsed_result = {
    'id' => fields[1],
    'full_name' => fields[2] + ' ' + fields[3],
  }
end

def parse_session(session)
  fields = session.split(',')
  parsed_result = {
    'user_id' => fields[1],
    'session_id' => fields[2],
    'browser' => fields[3],
    'time' => fields[4],
    'date' => fields[5],
  }
end

def collect_stats_from_users(report, users_objects)
  progressbar = ProgressBar.create(total: users_objects.count, title: 'Colculate stats:')
  users_objects.each do |user|
    user_key = user.full_name
    report['usersStats'][user_key] = {}
    report['usersStats'][user_key] = calc_stat(user)
    progressbar.increment
  end
end

def calc_stat(user)
  time = time_from_sesions(user)
  user_browsers = browsers_list(user)
  is_used_ie = used_ie(user_browsers)
  {
    'sessionsCount': sessions_count(user),
    'totalTime' => total_time(time),
    'longestSession' => longest_session(time),
    'browsers' => browsers(user_browsers),
    'usedIE' => is_used_ie,
    'alwaysUsedChrome' => is_used_ie ? false : always_used_chrome(user_browsers),
    'dates' => dates(user)
  }
end

def sessions_count(user)
  user.sessions.count
end

def time_from_sesions(user)
  # binding.pry
  user.sessions.map {|s| s['time'].to_i }
end

def total_time(time)
  time.sum.to_s + ' min.'
end

def longest_session(time)
  time.max.to_s + ' min.'
end

def browsers_list(user)
  user.sessions.map {|s| s['browser'].upcase }.sort
end

def browsers(browsers)
  browsers.join(', ')
end

def used_ie(browsers)
  browsers.any? { |b| b =~ /INTERNET EXPLORER/ }
end

def always_used_chrome(browsers)
  browsers.all? { |b| b.upcase =~ /CHROME/ }
end

def dates(user)
  user.sessions.map{|s| s['date'].tr("\n", '') }.sort.reverse
end

def parse_file(file)
  users = []
  sessions = []

  lines_count = `wc -l #{file}`.strip.split(' ')[0].to_i
  progressbar = ProgressBar.create(total: lines_count, title: 'Read data from file:')

  File.readlines(file).each do |line|
    cols = line.split(',')
    users << parse_user(line) if cols[0] == 'user'
    sessions << parse_session(line) if cols[0] == 'session'
    progressbar.increment
  end
  [users, sessions]
end

def count_browsers(sessions)
  browsers = []

  progressbar = ProgressBar.create(total: sessions.count, title: 'Count uniq browsers:')
  sessions.each do |session|
    browsers << session['browser']
    progressbar.increment
  end
  browsers.uniq
end

def create_users_objects(users, sessions_by_user)
  users_objects = []
  progressbar = ProgressBar.create(total: users.count, title: 'Create users:')
  users.each do |user|
    attributes = user
    id = user['id']
    full_name = user['full_name']
    user_sessions = sessions_by_user[id]
    user_object = User.new(attributes: attributes, sessions: user_sessions, id: id, full_name: full_name)
    users_objects << user_object
    progressbar.increment
  end
  users_objects
end

def find_all_browsers(sessions)
  sessions
    .map { |s| s['browser'] }
    .map { |b| b.upcase }
    .sort
    .uniq
    .join(',')
end

def work(file='data.txt')

  users, sessions = parse_file(file)

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
  uniqueBrowsers = count_browsers(sessions)

  report['uniqueBrowsersCount'] = uniqueBrowsers.count

  report['totalSessions'] = sessions.count

  find_all_browsers_time = Benchmark.realtime do
    report['allBrowsers'] = find_all_browsers(sessions)
  end.round(4)
  puts "find_all_browsers Takes #{find_all_browsers_time} sec"


  sessions_by_user = sessions.group_by{|h| h["user_id"]}
  sessions_by_user.default = []

  users_objects = create_users_objects(users, sessions_by_user)

  report['usersStats'] = {}

  collect_stats_from_users(report, users_objects)

  File.write('result.json', "#{report.to_json}\n")
end
