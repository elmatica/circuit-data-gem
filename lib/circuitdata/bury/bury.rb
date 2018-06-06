module Circuitdata
  module Bury
    class << self
      def bury(data, *path, value)
        current_data = data
        path[0..-2].each_with_index do |part, i|
          if current_data[part].nil?
            current_data[part] = path[i + 1].is_a?(Integer) ? [] : {}
          end
          current_data = current_data[part]
        end
        if value.present?
          current_data[path.last] = value
        else
          current_data.delete(path.last)
        end
        data
      end
    end
  end
end
