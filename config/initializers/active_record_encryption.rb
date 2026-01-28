# frozen_string_literal: true

Rails.application.configure do
  config.active_record.encryption.primary_key =
    ENV.fetch("ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY") do
      Rails.application.secret_key_base[0..31]
    end
  config.active_record.encryption.deterministic_key =
    ENV.fetch("ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY") do
      Rails.application.secret_key_base[32..63]
    end
  config.active_record.encryption.key_derivation_salt =
    ENV.fetch("ACTIVE_RECORD_ENCRYPTION_DERIVATION_SALT") do
      Rails.application.secret_key_base[64..95]
    end
end
