require 'jerakia/filter/interpolate/cycle_detector'

class Jerakia
  class Filter
    class Interpolate < Jerakia::Filter
      def filter
        all_keys do |key|
          key.parse_values do |val|
            do_substr(val) if val.is_a?(String)
          end
        end
      end

      def do_substr(data)
        data.gsub!(/([%$])\{([^\}]*)\}/) do |text|
          type, key = Regexp.last_match.captures

          next type if key.empty?

          case type
          when '%'
            Jerakia.log.debug("scope substituion: #{text}")
            substitute_scope(key)
          when '$'
            Jerakia.log.debug("chained lookup substition: #{text}")
            substitute_lookup(key)
          end
        end
      end

      def substitute_scope(key)
        value = options[:scope][key.to_sym]
        if value.nil?
          Jerakia.log.warn("'#{key}' does not exist in scope, substituting an empty string")
        end
        value.to_s
      end

      def substitute_lookup(key_str)
        parts = key_str.split('::',2)
        key = parts[-1]
        namespace = parts[-2]&.split('/') || dataset.request.namespace

        key, *dig_path = key.split(/(?<!\\)\./)
        dig_path.map! {|s| s.gsub('\\.','.') }

        req = Marshal.load(Marshal.dump(dataset.request))
        req.key = key
        req.namespace = namespace
        req.lookup_type = :first
        req.cycle_detector ||= CycleDetector.new()
        req.cycle_detector.see("#{namespace.join('/')}::#{key}")

        answer = policy.run(req)
        payload = answer.payload

        if dig_path.any?
          Jerakia.log.debug("Digging into #{payload} with #{dig_path}")
          if payload.kind_of?(Hash)
            payload = Jerakia::Util.dig(payload, dig_path)
          else
            Jerakia.log.warn("Cannot dig into non-hash data")
          end
        end

        if payload.kind_of?(Array) or payload.kind_of?(Hash)
          Jerakia.log.warn("trying to substitute non-scalar payload, will be converted to a string")
        elsif payload.nil?
          Jerakia.log.warn("tried to look up #{key_str} for substitution, but no value was found; substituting an empty string")
        end

        payload.to_s
      end
    end
  end
end
