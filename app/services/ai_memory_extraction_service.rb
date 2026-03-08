# frozen_string_literal: true

class AiMemoryExtractionService
  GENERATION_CONFIG = { temperature: 0.2 }.freeze

  VALID_CATEGORIES = AiMemory.categories.keys.freeze

  def initialize(user:, activity_content:)
    @user = user
    @activity_content = activity_content
  end

  def call
    existing = @user.ai_memories.for_prompt.to_a
    response = generate_response(existing)
    parse_and_save(response, existing)
  end

  private

  def generate_response(existing)
    client = AiClient.for(@user)
    client.generate(
      build_prompt(existing),
      generation_config: GENERATION_CONFIG,
      log_context: {
        user: @user,
        action: "memory_extraction"
      }
    )
  end

  def build_prompt(existing)
    lines = []
    lines << "## Existing Memories About This User"
    if existing.any?
      existing.each do |m|
        lines << "- [#{m.category}] (importance: #{m.importance}) #{m.content}"
      end
    else
      lines << "(none yet)"
    end

    lines << ""
    lines << "## Recent AI Activity Output"
    lines << @activity_content

    lines << ""
    lines << <<~PROMPT.strip
      ## Task
      Extract factual observations about this user from the activity output above.
      Focus on stable facts: schedule patterns, equipment available, injuries/limitations,
      exercise preferences, behavioral patterns, goals, and progress milestones.

      Rules:
      - Output one observation per line in format: [category]|importance|content
      - Valid categories: #{VALID_CATEGORIES.join(", ")}
      - Importance is 1-10: health/injuries=9, goals=8, equipment=7, schedule=6, preferences=5, progress=4, behavior=3. Adjust based on significance.
      - Keep each observation under 200 characters
      - Do not repeat observations already in existing memories
      - If an observation supersedes an existing memory, prefix with REPLACES: <old content>|[category]|importance|new content
      - If there are no new observations, respond with just: NONE
      - Do not include speculative or uncertain observations
      - Do not include generic fitness advice — only user-specific facts
    PROMPT

    lines.join("\n")
  end

  def parse_and_save(response, existing)
    return [] if response.strip.upcase == "NONE"

    existing_contents = existing.map { |m| m.content.downcase }
    memories = []

    response.each_line do |line|
      line = line.strip
      next if line.blank?

      if line.start_with?("REPLACES:")
        handle_replacement(line, memories)
      else
        handle_new_memory(line, existing_contents, memories)
      end
    end

    memories
  end

  def handle_replacement(line, memories)
    rest = line.sub(/^REPLACES:\s*/, "")
    parts = rest.split("|", 4)
    # Support both old format (3 parts) and new format (4 parts with importance)
    if parts.length == 4
      old_content = parts[0].strip
      category = parts[1].strip.tr("[]", "")
      importance = parse_importance(parts[2].strip, category)
      new_content = parts[3].strip
    elsif parts.length == 3
      old_content = parts[0].strip
      category = parts[1].strip.tr("[]", "")
      new_content = parts[2].strip
      importance = nil
    else
      return
    end
    return unless valid_entry?(category, new_content)

    old_memory =
      @user.ai_memories.find_by("LOWER(content) = ?", old_content.downcase)
    old_memory&.destroy

    memories << create_memory(category, new_content, importance)
  end

  def handle_new_memory(line, existing_contents, memories)
    parts = line.split("|", 3)
    # Support both old format (2 parts) and new format (3 parts with importance)
    if parts.length == 3
      category = parts[0].strip.tr("[]", "")
      importance = parse_importance(parts[1].strip, category)
      content = parts[2].strip
    elsif parts.length == 2
      category = parts[0].strip.tr("[]", "")
      content = parts[1].strip
      importance = nil
    else
      return
    end
    return unless valid_entry?(category, content)
    return if existing_contents.include?(content.downcase)

    memories << create_memory(category, content, importance)
  end

  def valid_entry?(category, content)
    VALID_CATEGORIES.include?(category) && content.present? &&
      content.length <= 500
  end

  def parse_importance(value, category)
    int_val = value.to_i
    if int_val >= 1 && int_val <= 10
      int_val
    else
      AiMemory::CATEGORY_IMPORTANCE.fetch(category, 5)
    end
  end

  def create_memory(category, content, importance = nil)
    importance ||= AiMemory::CATEGORY_IMPORTANCE.fetch(category, 5)
    memory =
      @user.ai_memories.create!(
        ai_trainer: @user.ai_trainer,
        category: category,
        content: content,
        importance: importance
      )
    generate_embedding(memory)
    memory
  end

  def generate_embedding(memory)
    client = AiClient.for(@user)
    return unless client.respond_to?(:generate_embedding)

    vector = client.generate_embedding(memory.content)
    memory.update!(embedding: vector.to_json)
  rescue AiClients::Base::Error => e
    Rails.logger.warn(
      "Failed to generate embedding for memory #{memory.id}: #{e.message}"
    )
  end
end
