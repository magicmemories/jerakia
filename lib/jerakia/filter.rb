class Jerakia
  class Filter
    def self.load(name, dataset, options, policy)
      begin
        require "jerakia/filter/#{name.to_s}"
      rescue LoadError => e
        raise Jerakia::Error, "Cannot load filter #{name.to_s}"
      end
      filter = instance_eval "Jerakia::Filter::#{name.to_s.capitalize}"
      return filter.new(dataset, options, policy)
    end

    attr_reader :dataset
    attr_reader :options
    attr_reader :policy

    def initialize(dataset, options, policy)
      @dataset = dataset
      @options = options
      @policy  = policy
    end

    def filter
    end

    def all_keys
      dataset.namespaces.each do | name, space |
        space.keys.each do |keyname, key|
          yield key
        end
      end
    end
  end
end

