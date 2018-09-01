require "net/http"

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
      hash_iterator(schema, schema)
    end

    private

    attr_reader :base_path

    def read_file(file_path)
      if file_path.start_with?("https://")
        file = get_remote_file(file_path)
      else
        file = File.read(file_path)
      end
      JSON.parse(file, symbolize_names: true)
    rescue => e
      puts file_path
      raise e
    end

    def dereferenced_read_file(file_path)
      if file_path.start_with?("https://")
        full_path = file_path
      else
        full_path = File.expand_path(file_path, base_path)
      end
      file_data = read_file(full_path)
      self.class.dereference(file_data, File.dirname(full_path))
    end

    def get_ref(ref, original_schema)
      file_path, pointer = ref.split("#")
      if file_path == ""
        data = original_schema
      else
        data = dereferenced_read_file(file_path)
      end
      pointer_parts = pointer.split("/").reject(&:blank?)
      result = data.dig(*pointer_parts.map(&:to_sym))
      if result.nil?
        fail "Unable to dereference ref=#{ref}"
      end
      result
    end

    def get_remote_file(url_str)
      url = URI.parse(url_str)
      req = Net::HTTP::Get.new(url.to_s)
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      res = http.request(req)
      if res.code != "200"
        raise StandardError.new("Expected 200 status got #{res.code.inspect} for #{url_str}")
      end
      res.body
    end

    def hash_iterator(h, original_schema)
      h = h.clone
      h.each_pair do |k, v|
        if v.is_a?(Hash)
          res = hash_iterator(v, original_schema)
          if res[:"$ref"]
            h[k] = res[:"$ref"]
          else
            h[k] = res
          end
        elsif v.is_a?(Array)
          h[k] = array_iterator(v, original_schema)
        else
          if k == :"$ref"
            ref_schema = get_ref(v, original_schema)
            return hash_iterator(ref_schema, original_schema)
          else
            h[k] = v
          end
        end
      end
      h
    end

    def array_iterator(arr, original_schema)
      arr.map do |v|
        if v.is_a?(Hash)
          hash_iterator(v, original_schema)
        elsif v.is_a?(Array)
          array_iterator(arr, original_schema)
        else
          v
        end
      end
    end
  end
end
