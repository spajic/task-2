require 'json'
require 'date'
require 'minitest/autorun'
require 'byebug'
require 'ruby-prof'
require 'benchmark'

class User
  attr_reader :attributes, :sessions

  def initialize(attributes:, sessions:)
    @attributes = attributes
    @sessions = sessions
  end
end

def parse_user(user)
  {
    id: user[1],
    full_name: "#{user[2]} #{user[3]}"
  }
end

def parse_session(session)
  {
    session_id: session[2],
    browser: session[3].upcase!,
    time: session[4].to_i,
    date: session[5]
  }
end

def collect_stats_from_users(report, users_objects)
  while users_objects.size.positive?
    user = users_objects.shift
    report[:usersStats][user.attributes[:full_name]] ||= {}
    report[:usersStats][user.attributes[:full_name]].merge!(yield(user))
  end
end

def work(file_path)
  users = []
  sessions = Hash.new { |hash, key| hash[key] = [] }
  sessions_count = 0

  File.foreach(file_path) do |line|
    line = line.split(',')
    users << parse_user(line) if line[0] == 'user'
    if line[0] == 'session'
      sessions[line[1]] << parse_session(line)
      sessions_count += 1
    end
  end

  report = {}
  report[:totalUsers] = users.count
  unique_browsers = sessions.values.flatten.map! { |session| session[:browser] }.uniq! || []
  report[:uniqueBrowsersCount] = unique_browsers.count
  report[:totalSessions] = sessions_count
  report[:allBrowsers] = unique_browsers.sort!.join(',')

  users.map! do |user|
    user_id = user[:id]
    user_sessions = sessions[user_id]
    User.new(attributes: user, sessions: user_sessions)
  end
  report[:usersStats] = {}

  collect_stats_from_users(report, users) do |user|
    users_times = user.sessions.map { |s| s[:time] }
    users_browsers = user.sessions.map { |s| s[:browser] }
    ie_count = 0
    chrome_count = 0
    users_browsers.each do |b|
      ie_count += 1 if /INTERNET EXPLORER/.match?(b)
      chrome_count += 1 if /CHROME/.match?(b)
    end

    {
      'sessionsCount' => user.sessions.count,
      'totalTime' => "#{users_times.sum} min.",
      'longestSession' => "#{users_times.max} min.",
      'browsers' => users_browsers.sort!.join(', '),
      'usedIE' => ie_count.positive?,
      'alwaysUsedChrome' => chrome_count == users_browsers.size,
      'dates' => user.sessions.map { |s| Date.parse(s[:date]).iso8601 }.sort!.reverse!
    }
  end

  File.write('result.json', "#{report.to_json}\n")
end

class TestMe < Minitest::Test
  def test_result
    File.write('result.json', '')
    work('fixtures/data_fixture.txt')
    expected_result = File.read('fixtures/expected_result_fixture.json')
    assert_equal expected_result, File.read('result.json')
  end

  def test_regress
    time = Benchmark.realtime { work('fixtures/data_fixture.txt') }
    assert time < 0.001, 'Test regress'
  end
end

# filename = ENV['DATA'] || 'data/data_05mb.txt'
# GC.disable if ENV['DATA']
# puts Process.pid
# work(filename)
