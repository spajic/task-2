require 'json'
require 'pry'
require 'date'
require 'minitest/autorun'
require 'benchmark'
require 'memory_profiler'

class User
  attr_reader :attributes, :sessions

  def initialize(attributes:, sessions:)
    @attributes = attributes
    @sessions = sessions
  end
end

IE_REG = /INTERNET EXPLORER/.freeze
CHROME_REG = /CHROME/.freeze
COMMA = ','.freeze

def parse_user(user)
  fields = user.split(COMMA)
  {
    'id' => fields[1],
    'first_name' => fields[2],
    'last_name' => fields[3],
    'age' => fields[4]
  }
end

def parse_session(session)
  fields = session.split(COMMA)
  {
    'user_id' => fields[1],
    'session_id' => fields[2],
    'browser' => fields[3].upcase,
    'time' => fields[4].to_i,
    'date' => Date.strptime(fields[5]).iso8601
  }
end

def collect_stats_from_users(report, users_objects, &block)
  users_objects.each do |user|
    user_key = user.attributes['first_name'] << ' ' << user.attributes['last_name']
    report['usersStats'][user_key] ||= {}
    report['usersStats'][user_key].merge!(block.call(user))
  end
end

def process_user_data(line)
  User.new(attributes: parse_user(line), sessions: [])
end

def work(file = 'data/data_large.txt', disable_gc: false)
  unique_browsers = []
  users_objects = []

  File.read(file).split("\n").each do |line|
    next users_objects.push(process_user_data(line)) if line.start_with?('user')

    users_objects.last.sessions.push(parse_session(line))
    next if unique_browsers.include?(users_objects.last.sessions.last['browser'])

    unique_browsers << users_objects.last.sessions.last['browser']
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

  report[:totalUsers] = users_objects.count

  report['uniqueBrowsersCount'] = unique_browsers.count

  report['totalSessions'] = users_objects.flat_map(&:sessions).count

  report['allBrowsers'] = unique_browsers.sort.join(',')

  report['usersStats'] = {}

  collect_stats_from_users(report, users_objects) do |user|
    tme = user.sessions.map { |s| s['time'] }
    brw = user.sessions.map { |s| s['browser'] }
    {
      'sessionsCount' => user.sessions.count,
      'totalTime' => tme.sum.to_s << ' min.',
      'longestSession' => tme.max.to_s << ' min.',
      'browsers' => brw.sort.join(', '),
      'usedIE' => brw.any? { |b| b =~ IE_REG },
      'alwaysUsedChrome' => brw.all? { |b| b =~ CHROME_REG },
      'dates' => user.sessions.map! { |s| s['date'] }.sort.reverse
    }
  end

  File.write('result.json', "#{report.to_json}\n")
end
