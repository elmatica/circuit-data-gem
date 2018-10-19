require "json-schema"
UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/

class UuidChecker
  def self.call(value)
    unless UUID_REGEX.match?(value)
      raise JSON::Schema::CustomFormatError.new("is not a uuid")
    end
  end
end

JSON::Validator.register_format_validator("uuid", UuidChecker)
