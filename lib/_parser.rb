require 'forwardable'
require_relative 'user'
require_relative 'report'

class Parser
  @parsed_user = User.new

  class << self
    extend Forwardable

    attr_reader :parsed_user

    def parse_user(first_name, last_name)
      @parsed_user.name = "#{first_name} #{last_name}"
    end

    def parse_session(browser, time, date)
      @parsed_user.sessions_count += 1

      @parsed_user.total_time += time
      @parsed_user.longest_session = time if @parsed_user.longest_session < time
      @parsed_user.browsers << browser
      Report.unique_browsers << browser

      @parsed_user.dates << date
    end

    private
    def_delegator :@parsed_user, :name, :parsed_exists?
    def_delegator :@parsed_user, :reset, :clear_cache
  end
end
