# frozen_string_literal: true
require 'oj'
require 'pry'
require 'date'
require 'set'

User = Struct.new(:id, :first_name, :last_name, :age)
Session =  Struct.new(:user_id, :session_id, :browser, :time, :date)

def parse_user(fields)
  User.new(fields[1], fields[2], fields[3], fields[4])
end

def parse_session(fields)
  Session.new(fields[1], fields[2], fields[3], fields[4], fields[5])
end

def collect_uniq_browsers(sessions)
  uniqueBrowsers = Set.new
  sessions.each { |session| uniqueBrowsers.add(session.browser) }
  uniqueBrowsers
end

def collect_user_stats(users, sessions)
  stat = {}
  users.each do |user|
    user_sessions = sessions[user.id]
    user_key = "#{user.first_name}" + ' ' + "#{user.last_name}"
    stat[user_key] =
      {
        'sessionsCount' => user_sessions.count,
        'totalTime' => user_sessions.map {|s| s.time}.map {|t| t.to_i}.sum.to_s + ' min.',
       'longestSession' => user_sessions.map {|s| s.time}.map {|t| t.to_i}.max.to_s + ' min.',
       'browsers' => user_sessions.map {|s| s.browser}.map {|b| b.upcase}.sort.join(', '),
       'usedIE' => user_sessions.map{|s| s.browser}.any? { |b| b.upcase =~ /INTERNET EXPLORER/ },
       'alwaysUsedChrome' => user_sessions.map{|s| s.browser}.all? { |b| b.upcase =~ /CHROME/ },
       'dates' => user_sessions.map { |s| Date.strptime(s.date, "%Y-%m-%d") }.sort!.reverse.map! { |d| d.iso8601 }
      }
  end
  stat
end

def split_line(line)
  line.split(',')
end

def work(file, disable_gc = false)
  GC.disable if disable_gc
  file_lines = File.read(file).split("\n")

  users = []
  sessions = {}

  File.open(file).each do |line|
    cols = split_line(line)
    users = users.push(parse_user(cols)) if cols[0] == 'user'

    if cols[0] == 'session'
      id = cols[1]
      sessions[id] ||= []
      sessions[id].push(parse_session(cols))
    end
  end

  report = {}

  report['totalUsers'] = users.count

  all_sessions = sessions.values.flatten
  uniqueBrowsers = collect_uniq_browsers(all_sessions)

  report['uniqueBrowsersCount'] = uniqueBrowsers.count

  report['totalSessions'] = all_sessions.count

  report['allBrowsers'] =
    all_sessions
      .map { |s| s.browser }
      .map { |b| b.upcase }
      .sort
      .uniq
      .join(',')

  report['usersStats'] = collect_user_stats(users, sessions)

  File.write('tmp/result.json', "#{Oj.dump(report)}\n")
end
