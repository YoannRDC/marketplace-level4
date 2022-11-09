require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :chrome, screen_size: [1400, 1400]

  Capybara.server = :puma
  Capybara.default_driver = :selenium_chrome
  #Capybara.current_driver = :selenium
  Capybara.run_server = false
  Capybara.app_host = 'http://localhost'
  Capybara.always_include_port = false
  # Capybara.server_host = 'localhost'

  Selenium::WebDriver.logger.level = Logger::DEBUG
  Webdrivers::Chromedriver.required_version = '107.0.5304.62'

end
