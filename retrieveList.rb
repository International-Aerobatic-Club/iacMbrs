require 'yaml'
require 'uri'
require 'capybara/dsl'

class Golden
  include Capybara::DSL

  def initialize(config)
    @config = config
  end

  def retriever()
    url = URI.parse(@config['url'])
    root = url.scheme + '://' + url.host
    Capybara.configure do |cap|
      cap.current_driver = :selenium
      cap.app_host = root
      cap.default_max_wait_time = 30 # seconds
    end

    puts "Visiting #{url.path} at #{root}"
    visit(url.path)

    puts 'Signing-in...'
    fill_in('username', with: @config['uname'])
    fill_in('password', with: @config['pwd'])
    select(@config['dom'], from: 'domain')
    click_button('loginButton')

    puts 'Navigating to download area'
    link = find(:xpath, '//a[text()="Partner upload/download area"]')
    popup = window_opened_by do
      link.click
    end

    puts "Selecting #{@config['filename']}"
    within_window(popup) do
      test = "text()=\"#{@config['filename']}\""
      puts "TEST #{test}"
      file_cell = find(:xpath, "//td[#{test}]")
      file_cell.click

      puts 'Selecting the download action'
      download_cell = find(:xpath, '//table[@id="fileMenu"]//td/font[contains(text(),"Download")]')
      download_cell.click

      puts 'Allowing download'
      # i have a modal here
      sleep(30)
    end
  end
end

config = YAML.load(File.read('config.yml'))
golden = Golden.new(config)
golden.retriever
