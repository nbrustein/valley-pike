# frozen_string_literal: true

require "rspec/core/formatters/base_text_formatter"
require "rspec/core/formatters/console_codes"
require "set"

class HostBinRerunFormatter < RSpec::Core::Formatters::BaseTextFormatter
  RSpec::Core::Formatters.register self,
                                  :message,
                                  :example_passed,
                                  :example_pending,
                                  :example_failed,
                                  :start_dump,
                                  :dump_summary,
                                  :dump_failures,
                                  :dump_pending,
                                  :seed

  include RSpec::Core::ShellEscape

  def example_passed(_notification)
    output.print RSpec::Core::Formatters::ConsoleCodes.wrap(".", :success)
  end

  def example_pending(_notification)
    output.print RSpec::Core::Formatters::ConsoleCodes.wrap("*", :pending)
  end

  def example_failed(_notification)
    output.print RSpec::Core::Formatters::ConsoleCodes.wrap("F", :failure)
  end

  def start_dump(_notification)
    output.puts
  end

  def dump_summary(summary)
    output.puts formatted_summary(summary)
    output.puts formatted_rerun_commands(summary) if summary.failed_examples.any?
  end

  private

  def formatted_summary(summary)
    "\nFinished in #{summary.formatted_duration} " \
      "(files took #{summary.formatted_load_time} to load)\n" \
      "#{summary.colorized_totals_line}\n"
  end

  def formatted_rerun_commands(summary)
    commands = summary.failed_examples.map do |example|
      command = "host-bin/test #{rerun_argument_for(example)}"
      colorized_command = RSpec::Core::Formatters::ConsoleCodes.wrap(
        command,
        RSpec.configuration.failure_color
      )
      colorized_description = RSpec::Core::Formatters::ConsoleCodes.wrap(
        "# #{example.full_description}",
        RSpec.configuration.detail_color
      )
      "#{colorized_command} #{colorized_description}"
    end

    "\nFailed examples:\n\n" + commands.join("\n")
  end

  def rerun_argument_for(example)
    location = example.location_rerun_argument
    return location unless duplicate_rerun_locations.include?(location)

    conditionally_quote(example.id)
  end

  def duplicate_rerun_locations
    @duplicate_rerun_locations ||= begin
      locations = RSpec.world.all_examples.map(&:location_rerun_argument)
      Set.new.tap do |set|
        locations.group_by {|location| location }.each do |location, locations_for_file|
          set << location if locations_for_file.count > 1
        end
      end
    end
  end
end
