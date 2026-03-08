# frozen_string_literal: true

namespace :ai_memories do
  desc "Backfill importance scores based on category defaults"
  task backfill_importance: :environment do
    updated = 0
    AiMemory
      .where(importance: 5)
      .find_each do |memory|
        default = AiMemory::CATEGORY_IMPORTANCE.fetch(memory.category, 5)
        next if default == 5

        memory.update_column(:importance, default)
        updated += 1
      end
    puts "Updated importance for #{updated} memories."
  end

  desc "Backfill embeddings for memories that don't have one"
  task backfill_embeddings: :environment do
    User
      .joins(:ai_memories)
      .distinct
      .find_each do |user|
        next if user.ai_api_key.blank?

        client = AiClient.for(user)
        next unless client.respond_to?(:generate_embedding)

        memories = user.ai_memories.where(embedding: nil)
        puts "User #{user.id}: #{memories.count} memories to embed"

        memories.find_each do |memory|
          vector = client.generate_embedding(memory.content)
          memory.update!(embedding: vector.to_json)
          print "."
        rescue AiClients::Base::Error => e
          puts "\nFailed for memory #{memory.id}: #{e.message}"
        end
        puts
      end
    puts "Done!"
  end
end
