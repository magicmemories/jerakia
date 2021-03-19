class Jerakia
  class Filter
    class Interpolate < Jerakia::Filter
      class CycleDetector
        def initialize
          @seen = []
        end

        def see(new_key)
          if @seen.include?(new_key)
            raise Jerakia::Error, "Encountered circular reference interpolating #{new_key}!"
          else
            @seen << new_key
          end
        end
      end
    end
  end
end
