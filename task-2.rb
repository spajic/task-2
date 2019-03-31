# Deoptimized version of homework task

require 'json'
require 'oj'
require 'set'
# require 'date'
require 'byebug'
require 'ruby-progressbar'


class User
  attr_reader :attributes, :sessions, :key

  def initialize(attributes:, sessions:)
    @attributes = attributes
    @sessions = sessions
    @key = "#{attributes[:first_name]}" + ' ' + "#{attributes[:last_name]}"
  end
end

INTERNET_EXPLORER = 'INTERNET EXPLORER'
CHROME = 'CHROME'
COMMA = ','

def parse_user(user)
  fields = user.split(COMMA)
  parsed_result = {
    id: fields[1],
    first_name: fields[2],
    last_name: fields[3],
    age: fields[4],
  }
end

def parse_session(session)
  fields = session.split(COMMA)
  parsed_result = {
    user_id: fields[1],
    session_id: fields[2],
    browser: fields[3].upcase!,
    time: fields[4],
    date: fields[5],
  }
end

def collect_stats_from_users(report, users_objects, progress: false, progress_bar: nil)
  users_objects.each do |user|
    progress_bar.increment if progress
    user_key = "#{user.key}"
    report[:usersStats][user_key] ||= {}

    time_array = user.sessions[user.attributes[:id]].map {|s| s[:time].to_i}
    # amount of sessions by user
    report[:usersStats][user_key][:sessionsCount] = count_sessions(user)

    # amount of time by user
    report[:usersStats][user_key][:totalTime] = session_time(time_array)

    # the longest session per user
    report[:usersStats][user_key][:longestSession] = user_longest_session(time_array)

    # user's browsers
    report[:usersStats][user_key][:browsers] = user_browsers(user)

    # used IE?
    report[:usersStats][user_key][:usedIE] = used_ie?(user)

    # always use chrome?
    report[:usersStats][user_key][:alwaysUsedChrome] = always_use_chrome?(user)

    report[:usersStats][user_key][:dates] = user_sessions_dates(user)
    report[:usersStats][user_key]
  end
end

def count_sessions(user)
  user.sessions[user.attributes[:id]].count
end

def session_time(time_array)
  time_array.sum.to_s + ' min.'
end

def user_longest_session(time_array)
  time_array.max.to_s + ' min.'
end

def user_browsers(user)
  user.sessions[user.attributes[:id]].map {|s| s[:browser]}.sort.join(', ')
end

def used_ie?(user)
  user.sessions[user.attributes[:id]].map{|s| s[:browser]}.any? { |b| b.include?(INTERNET_EXPLORER) }
end

def always_use_chrome?(user)
  user.sessions[user.attributes[:id]].map{|s| s[:browser]}.all? { |b| b.include?(CHROME) } 
end

def user_sessions_dates(user)
  user.sessions[user.attributes[:id]].map!{|s| s[:date]}.sort!.reverse!
end

def fill_user_objects(user, user_sessions, users_objects)
  attributes = user

  user_object = User.new(attributes: attributes, sessions: user_sessions)
  user_object
end

def work(file, target_json, progress: false)
  # byebug
  file_lines = File.read(file).split("\n")
  report = {}
  users = []
  sessions = []
  user_sessions = {}
  unique_browsers = Set.new([])

  file_lines.each do |line|   
    users << parse_user(line) if line.start_with?('user')
    next unless line.start_with?('session')
    session = parse_session(line) 
    sessions << session
    user_sessions[session[:user_id]] ||= []
    user_sessions[session[:user_id]] << session
    browser = session[:browser]
    unique_browsers << browser
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

  report[:totalUsers] = users.count

  report[:uniqueBrowsersCount] = unique_browsers.size

  report[:totalSessions] = sessions.count

  report[:allBrowsers] = unique_browsers.sort.join(',')
  report[:usersStats] = {}

  # Users stats
  users_objects = []

  users.each do |user|
    users_objects << fill_user_objects(user, user_sessions, users_objects)
  end

  progress_bar = ProgressBar.create(
    format: "%a %b\u{15E7}%i %p%% %t",
    progress_mark: ' ',
    remainder_mark: "\u{FF65}",
    total: users_objects.size
  ) if progress
  # byebug
  collect_stats_from_users(report, users_objects, progress: progress, progress_bar: progress_bar)

  # File.write(target_json, "#{report.to_json}\n")
  File.open(target_json,"w") do |f|
    f.write(Oj.dump(report, mode: :compat))
  end
end

