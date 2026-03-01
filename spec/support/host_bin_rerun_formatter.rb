# frozen_string_literal: true

require "rspec/core/formatters/console_codes"
require "rspec/core/notifications"

module HostBinRerunCommands
  # Show `host-bin/test` command
  def colorized_rerun_commands(colorizer=::RSpec::Core::Formatters::ConsoleCodes)
    commands = failed_examples.map do |example|
      command = "host-bin/test #{rerun_argument_for(example)}"
      colorizer.wrap(command, RSpec.configuration.failure_color) + " " +
        colorizer.wrap("# #{example.full_description}", RSpec.configuration.detail_color)
    end

    "\nFailed examples:\n\n" + commands.join("\n")
  end
end

RSpec::Core::Notifications::SummaryNotification.prepend(HostBinRerunCommands)
