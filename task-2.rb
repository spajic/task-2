require 'set'
require 'oj'
require 'date'

IE_PATTERN = 'INTERNET EXPLORER'.freeze
CHROME_PATTERN = 'CHROME'.freeze
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
    sessions_stats = {
      total_duration: 0,
      max_duration: 0,
      browsers: [],
      dates: [],
      length: user_sessions.length
    }

    until user_sessions.empty?
      session = user_sessions.shift
      time = session[:time].to_i

      sessions_stats[:total_duration] += time
      sessions_stats[:max_duration] = time if sessions_stats[:max_duration] < time
      sessions_stats[:browsers] << session[:browser]
      sessions_stats[:dates] << session[:date].chomp!
    end

    report[:usersStats][user[:name]] = {
      sessionsCount: sessions_stats[:length],
      totalTime: "#{sessions_stats[:total_duration]} min.",
      longestSession: "#{sessions_stats[:max_duration]} min.",
      browsers: sessions_stats[:browsers].sort!.join(DELIMITER),
      usedIE: sessions_stats[:browsers].any? { |b| b.start_with?(IE_PATTERN) },
      alwaysUsedChrome: sessions_stats[:browsers].all? { |b| b.start_with?(CHROME_PATTERN) },
      dates: sessions_stats[:dates].sort!.reverse!
    }
  end

  Oj.to_file(target_file, report, mode: :wab)
end
