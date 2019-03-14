require 'set'
require 'oj'
require 'date'

IE_PATTERN = /^INTERNET EXPLORER/.freeze
CHROME_PATTERN = /^CHROME/.freeze
COMMA = ','.freeze
DELIMITER = ', '.freeze
USER_ROW_MARK = 'user'.freeze
SESSION_ROW_MARK = 'session'.freeze

def parse_user(user)
  fields = user.split(COMMA)
  {
    id: fields[1],
    name: "#{fields[2]} #{fields[3]}".to_sym
  }
end

def parse_session(session)
  fields = session.split(COMMA)
  {
    user_id: fields[1],
    session_id: fields[2],
    browser: fields[3],
    time: fields[4],
    date: fields[5]
  }
end

def create_report(source_file, target_file)
  users = []
  sessions_by_users = {}
  unique_browsers = SortedSet.new
  total_sessions = 0

  File.open(source_file, 'r').each do |line|
    users << parse_user(line) if line.start_with?(USER_ROW_MARK)
    next unless line.start_with?(SESSION_ROW_MARK)

    session = parse_session(line)
    sessions_by_users[session[:user_id]] ||= []
    sessions_by_users[session[:user_id]] << session
    browser = session[:browser].upcase!
    unique_browsers << browser
    total_sessions += 1
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
  report[:uniqueBrowsersCount] = unique_browsers.size
  report[:totalSessions] = total_sessions
  report[:allBrowsers] = unique_browsers.to_a.join(COMMA)
  report[:usersStats] = {}

  until users.empty?
    user = users.shift
    user_sessions = sessions_by_users.delete(user[:id]) || []
    sessions_duration = user_sessions.map { |s| s[:time].to_i }
    browsers = user_sessions.map { |s| s[:browser] }

    report[:usersStats][user[:name]] = {
      sessionsCount: user_sessions.count,
      totalTime: "#{sessions_duration.sum} min.",
      longestSession: "#{sessions_duration.max} min.",
      browsers: browsers.sort!.join(DELIMITER),
      usedIE: browsers.any? { |b| b =~ IE_PATTERN },
      alwaysUsedChrome: browsers.all? { |b| b =~ CHROME_PATTERN },
      dates: user_sessions.map { |s| Date.strptime(s[:date], '%Y-%m-%d') }.sort!.reverse!.map!(&:iso8601)
    }
  end

  Oj.to_file(target_file, report, mode: :wab)
end
