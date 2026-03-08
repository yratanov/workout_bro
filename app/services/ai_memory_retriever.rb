# frozen_string_literal: true

class AiMemoryRetriever
  WEIGHTS = { similarity: 0.5, recency: 0.3, importance: 0.2 }.freeze
  LIMIT = 25
  MAX_PER_CATEGORY = 5
  RECENCY_HALF_LIFE_DAYS = 90.0

  def initialize(user:, prompt:)
    @user = user
    @prompt = prompt
  end

  def call
    memories = @user.ai_memories.to_a
    return [] if memories.empty?

    prompt_embedding = fetch_prompt_embedding
    scored =
      memories.map do |m|
        { memory: m, score: composite_score(m, prompt_embedding) }
      end

    scored
      .sort_by { |s| -s[:score] }
      .group_by { |s| s[:memory].category }
      .flat_map { |_, mems| mems.first(MAX_PER_CATEGORY) }
      .sort_by { |s| -s[:score] }
      .first(LIMIT)
      .map { |s| s[:memory] }
  end

  private

  def fetch_prompt_embedding
    return nil if @prompt.blank?

    client = AiClient.for(@user)
    return nil unless client.respond_to?(:generate_embedding)

    client.generate_embedding(@prompt)
  rescue StandardError
    nil
  end

  def composite_score(memory, prompt_embedding)
    sim = similarity_score(memory, prompt_embedding)
    rec = recency_score(memory.created_at)
    imp = memory.importance / 10.0

    if sim
      WEIGHTS[:similarity] * sim + WEIGHTS[:recency] * rec +
        WEIGHTS[:importance] * imp
    else
      # No embedding available — reweight to recency + importance only
      0.6 * rec + 0.4 * imp
    end
  end

  def similarity_score(memory, prompt_embedding)
    return nil unless prompt_embedding

    memory_embedding = memory.embedding_vector
    return nil unless memory_embedding

    cosine_similarity(memory_embedding, prompt_embedding)
  end

  def recency_score(created_at)
    days_old = (Time.current - created_at) / 1.day
    Math.exp(-days_old * Math.log(2) / RECENCY_HALF_LIFE_DAYS)
  end

  def cosine_similarity(a, b)
    return 0.0 if a.length != b.length

    dot = 0.0
    norm_a = 0.0
    norm_b = 0.0

    a.each_with_index do |val_a, i|
      val_b = b[i]
      dot += val_a * val_b
      norm_a += val_a * val_a
      norm_b += val_b * val_b
    end

    denominator = Math.sqrt(norm_a) * Math.sqrt(norm_b)
    return 0.0 if denominator.zero?

    dot / denominator
  end
end
