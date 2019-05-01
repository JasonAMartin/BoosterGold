require "selenium-webdriver"

# configure the driver to run in headless mode
options = Selenium::WebDriver::Chrome::Options.new
options.add_argument('--headless')
driver = Selenium::WebDriver.for :chrome, options: options
driver.manage.timeouts.implicit_wait = 10

# navigate to a really super awesome blog
driver.navigate.to "https://readcomiconline.to/"
element = driver.find_element(:id => "tabmenucontainer")
# resize the window and take a screenshot
driver.manage.window.resize_to(800, 800)
driver.save_screenshot "google-screenshot2.png"
puts driver.page_source


# driver.manage.timeouts.implicit_wait = 10 # seconds

# driver.get "http://somedomain/url_that_delays_loading"
# element = driver.find_element(:id => "some-dynamic-element")