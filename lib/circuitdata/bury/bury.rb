module Circuitdata
  module Bury
    class << self
      def bury(data, *path, value)
        current_data = data
        path[0..-2].each_with_index do |part, i|
          current_data = next_level(part, path[i + 1], current_data)
        end
        if !value.nil?
          current_data[path.last] = value
        else
          current_data.delete(path.last)
        end
        data
      end

      def dig(data, *path)
        current_data = data
        path.each do |part|
          current_data = next_level(part, nil, current_data, initialize_missing: false)
          return nil if current_data.nil?
        end
        current_data
      end

      private

      def find_matching_hash(data, partial_hash)
        data.find do |el|
          partial_hash.all? { |k, v| el[k] == v }
        end
      end

      def next_level(part, next_part, current_data, initialize_missing: true)
        if part.is_a?(Hash)
          existing_hash = find_matching_hash(current_data, part)
          if !existing_hash
            return nil unless initialize_missing
            new_data = part.dup
            current_data.push(new_data)
            new_data
          else
            existing_hash
          end
        elsif current_data[part].nil?
          return nil unless initialize_missing
          next_is_array = next_part.is_a?(Integer) || next_part.is_a?(Hash)
          current_data[part] = next_is_array ? [] : {}
          current_data[part]
        else
          current_data[part]
        end
      end
    end
  end
end
