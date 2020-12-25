require 'yaml'
require 'uri'
require 'capybara/dsl'
require 'selenium-webdriver'

class Golden
  include Capybara::DSL

  attr_accessor :time_limit, :poll_interval
  attr_reader :download_dir, :config

  def initialize(config)
    self.time_limit = 180 # seconds
    self.poll_interval = 10 # seconds
    @config = config
    @download_dir = File.absolute_path(config['download_to'])
    @download_temp_name = File.join(download_dir, '*.part')
    raise("Directory contains file matching #{@download_temp_name}") if downloading?
  end

  def downloading?
    Dir.glob(@download_temp_name).any?
  end

  def wait_for_download
    Timeout.timeout(time_limit) do
      begin
        sleep(poll_interval)
      end while downloading?
    end
  end

  def configure_capybara(app_host)
    Capybara.register_driver :golden do |app|
      # The new way will be something like this
      ###options = Selenium::WebDriver::Firefox::Options.new
      ###options.add_preference('browser.download.folderList', 2) # magic number
      ###options.add_preference('browser.download.dir', download_dir)
      ###options.add_preference('browser.helperApps.neverAsk.saveToDisk',
      ###   'text/plain, application/octet-stream')
      ###Capybara::Selenium::Driver.new(app, browser: :firefox, options: options)
      #### That last line does not work as hoped
      # This way is deprecated in lib/selenium/webdriver/firefox/marionette/driver.rb
      # but still works
      # You can view the list of Firefox preferences by typing "about:config"
      #   into the Firefox address bar
      # Much web searching and experimentation yields these settings
      profile = Selenium::WebDriver::Firefox::Profile.new
      profile['browser.download.folderList'] = 2 # magic number
      profile['browser.download.dir'] = download_dir
      profile['browser.download.useDownloadDir'] = true
      profile['browser.helperApps.neverAsk.saveToDisk'] =
        'text/plain, application/octet-stream'
      Capybara::Selenium::Driver.new(app, browser: :firefox, profile: profile)
    end

    Capybara.configure do |cap|
      cap.default_driver = :golden
      cap.app_host = app_host
      cap.default_max_wait_time = 30 # seconds
    end
  end

  def retriever()
    url = URI.parse(config['url'])
    root = url.scheme + '://' + url.host

    configure_capybara(root)

    puts "Visiting #{url.path} at #{root}"
    visit(url.path)

    puts 'Signing-in...'
    fill_in('username', with: config['uname'])
    fill_in('password', with: config['pwd'])
    select(config['dom'], from: 'domain')
    click_button('loginButton')

    puts 'Navigating to download area'
    link = find(:xpath, '//span[text()="upload/download area"]')
    sleep(10)
    popup = window_opened_by do
      link.click
    end

    within_window(popup) do
      puts "Selecting #{config['filename']}"
      filename_test = "text()=\"#{config['filename']}\""
      file_cell = find(:xpath, "//td[#{filename_test}]")
      file_cell.click

      puts 'Selecting the download action'
      download_cell = find(:xpath, '//table[@id="fileMenu"]//td/font[contains(text(),"Download")]')
      download_cell.click

      puts 'Allowing download'
      wait_for_download
      puts "Find your file in #{download_dir}"
    end
  end
end

config = YAML.load(File.read('config.yml'))
golden = Golden.new(config)
golden.retriever
