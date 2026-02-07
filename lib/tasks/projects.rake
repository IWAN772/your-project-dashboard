# frozen_string_literal: true

require_relative "../project_scanner"

namespace :projects do
  desc "Scan development directory for git repositories and update database"
  task scan: :environment do
    # Configuration - can be moved to ENV vars later
    root_path = ENV.fetch("SCAN_ROOT_PATH", "~/Development")
    cutoff_days = ENV.fetch("SCAN_CUTOFF_DAYS", "240").to_i
    cutoff_date = Date.today - cutoff_days
    dry_run = ENV["DRY_RUN"] == "true"

    puts
    puts "=" * 80
    puts "PROJECT DASHBOARD SCANNER"
    puts "=" * 80
    puts
    puts "Root path: #{root_path}"
    puts "Cutoff date: #{cutoff_date} (~#{cutoff_days} days ago)"
    puts "Mode: #{dry_run ? 'DRY RUN (no database changes)' : 'LIVE'}"
    puts "=" * 80
    puts

    begin
      scanner = ProjectScanner.new(root_path, cutoff_date)
      scanner.scan

      unless dry_run
        scanner.save_to_database
      end

      scanner.print_summary

      puts
      puts "Done! 🎉"
      puts
    rescue => e
      puts
      puts "ERROR: #{e.message}"
      puts e.backtrace.first(10)
      exit 1
    end
  end

  desc "Show configuration for project scanner"
  task config: :environment do
    puts "Project Scanner Configuration:"
    puts "  SCAN_ROOT_PATH: #{ENV.fetch('SCAN_ROOT_PATH', '~/Development')} (default: ~/Development)"
    puts "  SCAN_CUTOFF_DAYS: #{ENV.fetch('SCAN_CUTOFF_DAYS', '240')} (default: 240 days / ~8 months)"
    puts "  DRY_RUN: #{ENV.fetch('DRY_RUN', 'false')} (default: false)"
    puts
    puts "Usage:"
    puts "  bin/rake projects:scan                    # Full scan and save"
    puts "  DRY_RUN=true bin/rake projects:scan       # Scan without saving"
    puts "  SCAN_ROOT_PATH=/path bin/rake projects:scan"
  end
end
