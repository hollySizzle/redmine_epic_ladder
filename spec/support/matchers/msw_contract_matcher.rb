# frozen_string_literal: true

# MSW契約適合性チェック用カスタムマッチャー
RSpec::Matchers.define :conform_to_msw_contract do |contract_name|
  match do |actual_response|
    @contract = MswContracts.const_get(contract_name)
    @actual = actual_response.is_a?(String) ? JSON.parse(actual_response, symbolize_names: true) : actual_response
    @errors = []

    check_structure(@contract, @actual, [])
    @errors.empty?
  end

  failure_message do |actual_response|
    error_messages = @errors.map { |path, expected, actual|
      "  - #{path.join('.')}: expected #{expected.inspect}, got #{actual.class} (#{actual.inspect})"
    }.join("\n")

    <<~MSG
      Expected response to conform to MSW contract :#{contract_name}

      Contract violations:
      #{error_messages}

      Full response:
      #{JSON.pretty_generate(@actual)}
    MSG
  end

  # 再帰的に構造をチェック
  def check_structure(expected, actual, path)
    case expected
    when Hash
      unless actual.is_a?(Hash)
        @errors << [path, Hash, actual]
        return
      end

      expected.each do |key, value|
        current_path = path + [key]

        # キーの存在チェック
        unless actual.key?(key)
          @errors << [current_path, "present", "missing"]
          next
        end

        check_structure(value, actual[key], current_path)
      end

    when Class
      # 型チェック（NilClassは特別扱い）
      unless actual.is_a?(expected)
        @errors << [path, expected, actual]
      end

    when Array
      # 配列の場合
      if expected.all? { |e| e.is_a?(Class) }
        # 複数の型を許容（例: [String, NilClass]）
        unless expected.any? { |klass| actual.is_a?(klass) }
          @errors << [path, "one of #{expected.inspect}", actual]
        end
      else
        # 配列要素の型チェックは行わない（空配列も許容）
        unless actual.is_a?(Array)
          @errors << [path, Array, actual]
        end
      end

    else
      # 値の完全一致チェック
      unless actual == expected
        @errors << [path, expected, actual]
      end
    end
  end
end

# 簡易版マッチャー（構造のみチェック、値は無視）
RSpec::Matchers.define :have_msw_structure do |contract_name|
  match do |actual_response|
    @contract = MswContracts.const_get(contract_name)
    @actual = actual_response.is_a?(String) ? JSON.parse(actual_response, symbolize_names: true) : actual_response

    has_required_keys?(@contract, @actual)
  end

  def has_required_keys?(expected, actual)
    return true unless expected.is_a?(Hash)
    return false unless actual.is_a?(Hash)

    expected.all? do |key, value|
      actual.key?(key) && has_required_keys?(value, actual[key])
    end
  end

  failure_message do |actual_response|
    <<~MSG
      Expected response to have MSW structure :#{contract_name}

      Actual response:
      #{JSON.pretty_generate(@actual)}
    MSG
  end
end
