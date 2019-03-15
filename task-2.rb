# Deoptimized version of homework task

require 'json'
require 'pry'
require 'date'
require 'set'

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
    'id' => fields[1],
    'first_name' => fields[2],
    'last_name' => fields[3],
    'age' => fields[4],
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

def collect_stats_from_users(report, users_objects, &block)
  users_objects.each do |user|
    user_key = "#{user.attributes['first_name']}" + ' ' + "#{user.attributes['last_name']}"
    report['usersStats'][user_key] ||= {}
    report['usersStats'][user_key] = report['usersStats'][user_key].merge(block.call(user))
  end
end

def create_users_objects(users, sessions)
  users_objects = []

  users.each do |user|
    attributes = user
    user_sessions = sessions[user['id']]
    user_object = User.new(attributes: attributes, sessions: user_sessions)
    users_objects = users_objects + [user_object]
  end
  users_objects
end

def collect_uniq_browsers(sessions)
  uniqueBrowsers = Set.new
  sessions.each { |session| uniqueBrowsers.add(session['browser']) }
  uniqueBrowsers
end

def collect_user_stats(users)
  stat = {}
  users.each do |user|
    user_key = "#{user.attributes['first_name']}" + ' ' + "#{user.attributes['last_name']}"
    stat[user_key] =
      {
        'sessionsCount' => user.sessions.count,
        'totalTime' => user.sessions.map {|s| s['time']}.map {|t| t.to_i}.sum.to_s + ' min.',
       'longestSession' => user.sessions.map {|s| s['time']}.map {|t| t.to_i}.max.to_s + ' min.',
       'browsers' => user.sessions.map {|s| s['browser']}.map {|b| b.upcase}.sort.join(', '),
       'usedIE' => user.sessions.map{|s| s['browser']}.any? { |b| b.upcase =~ /INTERNET EXPLORER/ },
       'alwaysUsedChrome' => user.sessions.map{|s| s['browser']}.all? { |b| b.upcase =~ /CHROME/ },
       'dates' => user.sessions.map { |s| Date.strptime(s['date'], "%Y-%m-%d") }.sort!.reverse.map! { |d| d.iso8601 }
      }
  end
  stat
end

def work(file, disable_gc = false)
  GC.disable if disable_gc
  file_lines = File.read(file).split("\n")

  users = []
  sessions = {}

  file_lines.each do |line|
    cols = line.split(',')
    users = users + [parse_user(line)] if cols[0] == 'user'

    if cols[0] == 'session'
      id = cols[1]
      sessions[id] ||= []
      sessions[id] << parse_session(line)
    end
  end

  report = {}

  report[:totalUsers] = users.count

  all_sessions = sessions.values.flatten
  uniqueBrowsers = collect_uniq_browsers(all_sessions)

  report['uniqueBrowsersCount'] = uniqueBrowsers.count

  report['totalSessions'] = all_sessions.count

  report['allBrowsers'] =
    all_sessions
      .map { |s| s['browser'] }
      .map { |b| b.upcase }
      .sort
      .uniq
      .join(',')

  users_objects = create_users_objects(users, sessions)
  report['usersStats'] = collect_user_stats(users_objects)

  File.write('result.json', "#{report.to_json}\n")
end
