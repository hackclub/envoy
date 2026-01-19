Grover.configure do |config|
  config.options = {
    format: "Letter",
    margin: {
      top: "0.75in",
      bottom: "0.75in",
      left: "1in",
      right: "1in"
    },
    print_background: true,
    prefer_css_page_size: false,
    emulate_media: "print",
    wait_until: "networkidle0",
    timeout: 30_000,
    launch_args: [ "--no-sandbox", "--disable-setuid-sandbox", "--disable-dev-shm-usage" ],
    executable_path: ENV.fetch("PUPPETEER_EXECUTABLE_PATH", nil)
  }
end
