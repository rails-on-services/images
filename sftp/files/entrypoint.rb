#!/usr/bin/env ruby

require_relative './entrylib'
entrypoint = Entrypoint.new
entrypoint.run!
entrypoint.write_supervisord
entrypoint.run_supervisord! if ARGV.length.zero? || ARGV[0].start_with?('-')
