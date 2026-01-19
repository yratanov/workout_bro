# frozen_string_literal: true

Rails.application.configure do
  config.active_record.encryption.primary_key = ENV.fetch("ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY") {
    Rails.application.secret_key_base[0..31]
  }
  config.active_record.encryption.deterministic_key = ENV.fetch("ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY") {
    Rails.application.secret_key_base[32..63]
  }
  config.active_record.encryption.key_derivation_salt = ENV.fetch("ACTIVE_RECORD_ENCRYPTION_DERIVATION_SALT") {
    Rails.application.secret_key_base[64..95]
  }
end
