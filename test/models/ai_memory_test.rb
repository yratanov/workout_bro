# == Schema Information
#
# Table name: ai_memories
# Database name: primary
#
#  id            :integer          not null, primary key
#  category      :integer          not null
#  content       :text             not null
#  source        :string           default("auto"), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  ai_trainer_id :integer
#  user_id       :integer          not null
#
# Indexes
#
#  index_ai_memories_on_ai_trainer_id         (ai_trainer_id)
#  index_ai_memories_on_user_id_and_category  (user_id,category)
#
# Foreign Keys
#
#  ai_trainer_id  (ai_trainer_id => ai_trainers.id)
#  user_id        (user_id => users.id)
#
require "test_helper"

class AiMemoryTest < ActiveSupport::TestCase
  test "valid memory" do
    memory = ai_memories(:johns_schedule)
    assert memory.valid?
  end

  test "requires content" do
    memory = AiMemory.new(user: users(:john), category: :schedule, content: "")
    assert_not memory.valid?
    assert_includes memory.errors[:content], "can't be blank"
  end

  test "validates content max length" do
    memory =
      AiMemory.new(user: users(:john), category: :schedule, content: "x" * 501)
    assert_not memory.valid?
    assert memory.errors[:content].any?
  end

  test "requires category" do
    memory = AiMemory.new(user: users(:john), content: "Test")
    assert_not memory.valid?
  end

  test "defines category enum" do
    expected = {
      "schedule" => 0,
      "equipment" => 1,
      "health" => 2,
      "preferences" => 3,
      "progress" => 4,
      "behavior" => 5,
      "goals" => 6
    }
    assert_equal expected, AiMemory.categories
  end

  test "belongs to user" do
    memory = ai_memories(:johns_schedule)
    assert_equal users(:john), memory.user
  end

  test "belongs to ai_trainer optionally" do
    memory = ai_memories(:johns_schedule)
    assert_equal ai_trainers(:johns_trainer), memory.ai_trainer
  end

  test "for_prompt scope orders by category integer asc then created_at desc" do
    memories = users(:john).ai_memories.for_prompt
    category_ints = memories.map { |m| AiMemory.categories[m.category] }
    assert_equal category_ints, category_ints.sort
  end

  test "user has_many ai_memories with dependent destroy" do
    user = users(:john)
    assert user.ai_memories.count > 0

    reflection = User.reflect_on_association(:ai_memories)
    assert_equal :destroy, reflection.options[:dependent]
  end

  test "ai_trainer has_many ai_memories with dependent nullify" do
    reflection = AiTrainer.reflect_on_association(:ai_memories)
    assert_equal :nullify, reflection.options[:dependent]
  end
end
