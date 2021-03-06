class GlobalSetting

  def self.load_defaults
    default_provider = FileProvider.from(File.expand_path('../../../config/discourse_defaults.conf', __FILE__))
    default_provider.data.each do |name, default|
      define_singleton_method(name) do
        provider.lookup(name, default)
      end
    end
  end


  class BaseProvider
    def self.coerce(setting)
      return setting == "true" if setting == "true" || setting == "false"
      return $1.to_i if setting.to_s.strip =~ /^([0-9]+)$/
      setting
    end


    def resolve(current, default)
      BaseProvider.coerce(
        if current.present?
          current
        else
          default.present? ? default : nil
        end
      )
    end
  end

  class FileProvider < BaseProvider
    attr_reader :data
    def self.from(file)
      if File.exists?(file)
        parse(file)
      end
    end

    def initialize(file)
      @file = file
      @data = {}
    end

    def read
      File.read(@file).split("\n").each do |line|
        if line =~ /([a-z_]+)\s*=\s*(\"([^\"]*)\"|\'([^\']*)\'|[^#]*)/
          @data[$1.strip.to_sym] = ($4 || $3 || $2).strip
        end
      end
    end


    def lookup(key,default)
      var = @data[key]
      resolve(var, var.nil? ? default : "")
    end


    private
    def self.parse(file)
      provider = self.new(file)
      provider.read
      provider
    end
  end

  class EnvProvider < BaseProvider
    def lookup(key, default)
      var = ENV["DISCOURSE_" << key.to_s.upcase]
      resolve(var , var.nil? ? default : nil)
    end
  end


  class << self
    attr_accessor :provider
  end


  load_defaults
  @provider =
    FileProvider.from(File.expand_path('../../../config/discourse.conf', __FILE__)) ||
    EnvProvider.new
end
