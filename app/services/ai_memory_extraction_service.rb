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
      existing.each { |m| lines << "- [#{m.category}] #{m.content}" }
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
      - Output one observation per line in format: [category]|content
      - Valid categories: #{VALID_CATEGORIES.join(", ")}
      - Keep each observation under 200 characters
      - Do not repeat observations already in existing memories
      - If an observation supersedes an existing memory, prefix with REPLACES: <old content>|[category]|new content
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
    parts = rest.split("|", 3)
    return unless parts.length == 3

    old_content = parts[0].strip
    category = parts[1].strip.tr("[]", "")
    new_content = parts[2].strip
    return unless valid_entry?(category, new_content)

    old_memory =
      @user.ai_memories.find_by("LOWER(content) = ?", old_content.downcase)
    old_memory&.destroy

    memories << create_memory(category, new_content)
  end

  def handle_new_memory(line, existing_contents, memories)
    parts = line.split("|", 2)
    return unless parts.length == 2

    category = parts[0].strip.tr("[]", "")
    content = parts[1].strip
    return unless valid_entry?(category, content)
    return if existing_contents.include?(content.downcase)

    memories << create_memory(category, content)
  end

  def valid_entry?(category, content)
    VALID_CATEGORIES.include?(category) && content.present? &&
      content.length <= 500
  end

  def create_memory(category, content)
    @user.ai_memories.create!(
      ai_trainer: @user.ai_trainer,
      category: category,
      content: content
    )
  end
end
