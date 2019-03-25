# Deoptimized version of homework task

require 'json'
require 'set'
require 'date'
require 'byebug'
require 'ruby-progressbar'


class User
  attr_reader :attributes, :sessions

  def initialize(attributes:, sessions:)
    @attributes = attributes
    @sessions = sessions
  end
end

def parse_user(user)
  fields = user.split(',')
  parsed_result = {
    id: fields[1],
    first_name: fields[2],
    last_name: fields[3],
    age: fields[4],
  }
end

def parse_session(session)
  fields = session.split(',')
  parsed_result = {
    user_id: fields[1],
    session_id: fields[2],
    browser: fields[3],
    time: fields[4],
    date: fields[5],
  }
end


def collect_stats_from_users(report, users_objects, progress: false, progress_bar: nil)
  users_objects.each do |user|
    progress_bar.increment if progress
    user_key = "#{user.attributes[:first_name]}" + ' ' + "#{user.attributes[:last_name]}"
    report[:usersStats][user_key] ||= {}

    # amount of sessions by user
    report[:usersStats][user_key][:sessionsCount] = count_sessions(user)

    # amount of time by user
    report[:usersStats][user_key][:totalTime] = session_time(user)

    # the longest session per user
    report[:usersStats][user_key][:longestSession] = user_longest_session(user)

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

def session_time(user)
  user.sessions[user.attributes[:id]].map {|s| s[:time]}.map {|t| t.to_i}.sum.to_s + ' min.'
end

def user_longest_session(user)
  user.sessions[user.attributes[:id]].map {|s| s[:time]}.map {|t| t.to_i}.max.to_s + ' min.'
end

def user_browsers(user)
  user.sessions[user.attributes[:id]].map {|s| s[:browser]}.map {|b| b.upcase}.sort.join(', ')
end

def used_ie?(user)
  user.sessions[user.attributes[:id]].map{|s| s[:browser]}.any? { |b| b.upcase =~ /INTERNET EXPLORER/ }
end

def always_use_chrome?(user)
  user.sessions[user.attributes[:id]].map{|s| s[:browser]}.all? { |b| b.upcase =~ /CHROME/ } 
end

def user_sessions_dates(user)
  user.sessions[user.attributes[:id]].map{|s| s[:date]}.map {|d| Date.parse(d)}.sort.reverse.map { |d| d.iso8601 }
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
    browser = session[:browser].upcase!
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
    f.write(report.to_json)
  end
end

