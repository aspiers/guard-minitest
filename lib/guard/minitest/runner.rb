# encoding: utf-8
module Guard
  class Minitest
    class Runner

      class << self

        def run(paths = [], options = {})
          Runner.new(options).run(paths, options)
        end

      end

      def initialize(options = {})
        parse_deprecated_options(options)

        @options = {
          :bundler            => File.exist?("#{Dir.pwd}/Gemfile"),
          :rubygems           => false,
          :drb                => false,
          :zeus               => false,
          :spring             => false,
          :test_folders       => %w[test spec],
          :test_file_patterns => %w[*_test.rb test_*.rb *_spec.rb],
          :cli                => ''
        }.merge(options)

        [:test_folders, :test_file_patterns].each do |k|
          @options[k] = Array(@options[k]).uniq.compact
        end
      end

      def run(paths, options = {})
        message = options[:message] || "Running: #{paths.join(' ')}"
        UI.info message, :reset => true
        system(minitest_command(paths))
      end

      def cli_options
        @options[:cli] ||= ''
      end

      def bundler?
        @options[:bundler] && ! @options[:spring]
      end

      def rubygems?
        !bundler? && @options[:rubygems]
      end

      def drb?
        @options[:drb]
      end

      def zeus?
        @options[:zeus].is_a?(String) || @options[:zeus]
      end

      def spring?
        @options[:spring]
      end

      def test_folders
        @options[:test_folders]
      end

      def test_file_patterns
        @options[:test_file_patterns]
      end

      private

      def minitest_command(paths)
        cmd_parts = []

        cmd_parts << "bundle exec" if bundler?
        if drb?
          cmd_parts << 'testdrb -Itest'
          cmd_parts += paths.map{ |path| "./#{path}" }
        elsif zeus?
          command = @options[:zeus].is_a?(String) ? @options[:zeus] : 'test'
          cmd_parts << "zeus #{command}"
          cmd_parts += paths.map{ |path| "./#{path}" }
        elsif spring?
          cmd_parts += %w{spring test}
          cmd_parts += paths
        else
          cmd_parts << 'ruby'
          cmd_parts += test_folders.map{|f| %[-I"#{f}"] }
          cmd_parts << '-r rubygems' if rubygems?
          cmd_parts << '-r bundler/setup' if bundler?
          cmd_parts += paths.map{ |path| "-r ./#{path}" }
          cmd_parts << "-r #{File.expand_path('../runners/default_runner.rb', __FILE__)}"
          cmd_parts << '-e \'MiniTest::Unit.autorun\''
          cmd_parts << '--' << cli_options unless cli_options.empty?
        end

        cmd_parts.join(' ')
      end

      def parse_deprecated_options(options)
        options[:cli] ||= ''

        if options.key?(:notify)
          UI.info %{DEPRECATION WARNING: The :notify option is deprecated. Guard notification configuration is used.}
        end

        [:seed, :verbose].each do |key|
          if value = options.delete(key)
             options[:cli] << " --#{key}"
            if ![TrueClass, FalseClass].include?(value.class)
              options[:cli] << " #{value}"
            end

            UI.info %{DEPRECATION WARNING: The :#{key} option is deprecated. Pass standard command line argument "--#{key}" to MiniTest with the :cli option.}
          end
        end
      end
    end
  end
end

