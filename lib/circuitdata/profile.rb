module Circuitdata
  class Profile
    BASIC_PROFILE_STRUCTURE = {
      open_trade_transfer_package: {
        version: SCHEMA_VERSION,
        profiles: {
          default: { circuitdata: { version: SCHEMA_VERSION } },
          restricted: { circuitdata: { version: SCHEMA_VERSION } },
          enforced: { circuitdata: { version: SCHEMA_VERSION } },
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

    def profile_data
      data.dig(:open_trade_transfer_package, :profiles)
    end

    def question_answer(path)
      path = path.map { |p| p.is_a?(String) ? p.to_sym : p }
      profile_data.dig(*path)
    end

    def set_question_answer(path, value)
      path = path.map { |p| p.is_a?(String) ? p.to_sym : p }
      return if value.nil? && question_answer(path).nil?
      Bury.bury(profile_data, *path, value)
    end

    private

    def setup_basic_data
      BASIC_PROFILE_STRUCTURE.deep_dup
    end
  end
end
