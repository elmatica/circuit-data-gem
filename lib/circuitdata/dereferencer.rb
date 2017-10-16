module Circuitdata
  class Dereferencer

    def self.dereference(schema, base_path)
      d = new(base_path)
      d.start(schema)
    end

    def initialize(base_path)
      @base_path = base_path
    end

    def start(schema)
      hash_iterator(schema)
    end

    private

    attr_reader :base_path

    def read_file(file_path)
      full_path = File.expand_path(file_path, base_path)
      file = File.read(full_path)
      JSON.parse(file, symbolize_names: true)
    end

    def get_ref(ref)
      file_path, pointer = ref.split('#')
      data = read_file(file_path)
      pointer_parts = pointer.split('/').reject(&:blank?)
      result = data.dig(*pointer_parts.map(&:to_sym))
      if result.nil?
        fail "Unable to dereference ref=#{ref}"
      end
      result
    end


    def hash_iterator(h)
      h = h.clone
      h.each_pair do |k,v|
        if v.is_a?(Hash)
          res = hash_iterator(v)
          if res[:"$ref"]
            h[k] = res[:"$ref"]
          else
            h[k] = res
          end
        elsif v.is_a?(Array)
          h[k] = array_iterator(v)
        else
          if k == :"$ref"
            ref_schema = get_ref(v)
            return hash_iterator(ref_schema)
          else
            h[k] = v
          end
        end
      end
      h
    end

    def array_iterator(arr)
      arr.map do |v|
        if v.is_a?(Hash)
          hash_iterator(v)
        elsif v.is_a?(Array)
          array_iterator(arr)
        else
          v
        end
      end
    end
  end
end
