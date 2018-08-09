module Circuitdata
  class Profile
    BASIC_PROFILE_STRUCTURE = {
      open_trade_transfer_package: {
        version: SCHEMA_VERSION,
        profiles: {
          default: {circuitdata: {version: SCHEMA_VERSION}},
          restricted: {circuitdata: {version: SCHEMA_VERSION}},
          enforced: {circuitdata: {version: SCHEMA_VERSION}},
        },
      },
    }
    def self.questions
      Schema.profile_questions
    end

    def initialize(data:)
      @data = data
    end

    def data
      @data ||= setup_basic_data
    end

    private

    def setup_basic_data
      BASIC_PROFILE_STRUCTURE.deep_dup
    end
  end
end
