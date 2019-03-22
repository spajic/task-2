# frozen_string_literal: true
require 'ruby-progressbar'
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
  Session.new(fields[1], fields[2], fields[3].upcase, fields[4], fields[5].strip)
end

def collect_uniq_browsers(sessions)
  uniqueBrowsers = Set.new
  sessions.each { |session| uniqueBrowsers.add(session.browser) }
  uniqueBrowsers
end

def collect_user_stats(users, sessions)
  stat = {}
  users.each do |user|
    user_key = "#{user.first_name} #{user.last_name}"
    user_sessions = sessions[user.id]
    user_browsers = user_sessions.map(&:browser).sort!
    user_times = user_sessions.map {|s| s.time.to_i }

    stat[user_key] =
      {
       'sessionsCount' => user_sessions.count,
       'totalTime' => user_times.sum.to_s + ' min.',
       'longestSession' => user_times.max.to_s + ' min.',
       'browsers' => user_browsers.join(', '),
       'usedIE' => user_browsers.any? { |b| b =~ /INTERNET EXPLORER/ },
       'alwaysUsedChrome' => user_browsers.all? { |b| b =~ /CHROME/ },
       'dates' => user_sessions.map(&:date).sort! { |x, y| y <=> x }
      }
  end
  stat
end

def split_line(line)
  line.split(',')
end

def work(file, disable_gc = false)
  GC.disable if disable_gc
  # file_lines = File.read(file).split("\n")
  # progressbar = ProgressBar.create(total: file_lines.length, format: '%a, %J, %E %B')

  users = []
  sessions = {}

  File.open(file).each do |line|
    # progressbar.increment
    cols = line.split(',')
    users = users.push(parse_user(cols)) if cols[0] == 'user'

    if cols[0] == 'session'
      id = cols[1]
      sessions[id] ||= []
      sessions[id].push(parse_session(cols))
    end
  end

  all_sessions = sessions.values.flatten
  uniqueBrowsers = collect_uniq_browsers(all_sessions)

  report = {
    'totalUsers' => users.count,
    'uniqueBrowsersCount' => uniqueBrowsers.count,
    'totalSessions' => all_sessions.count,
    'allBrowsers' => uniqueBrowsers.to_a.sort.join(','),
    'usersStats' => collect_user_stats(users, sessions)
  }

  File.write('tmp/result.json', "#{Oj.dump(report)}\n")
end
work('data/data_1m.txt')
