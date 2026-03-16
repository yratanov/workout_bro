#!/usr/bin/env ruby
# frozen_string_literal: true

# Helper script to generate synthetic VCR cassettes.
# Run: ruby test/cassettes/.generate_cassettes.rb
# This does NOT call any API — it just writes YAML files.

require "yaml"
require "json"

CASSETTE_DIR = File.expand_path(__dir__)
BASE_URL = "https://generativelanguage.googleapis.com/v1beta/models"
MODEL = "gemini-2.5-flash"
MODEL_20 = "gemini-2.0-flash"

def gemini_url(model, action, extra_query: nil)
  # WebMock normalizes query params alphabetically, so we must match that order
  if extra_query
    params = (extra_query.split("&") + ["key=<GEMINI_API_KEY>"]).sort
    "#{BASE_URL}/#{model}:#{action}?#{params.join("&")}"
  else
    "#{BASE_URL}/#{model}:#{action}?key=<GEMINI_API_KEY>"
  end
end

def success_body(text, input_tokens: 10, output_tokens: 20, total_tokens: 30)
  {
    "candidates" => [{ "content" => { "parts" => [{ "text" => text }] } }],
    "usageMetadata" => {
      "promptTokenCount" => input_tokens,
      "candidatesTokenCount" => output_tokens,
      "totalTokenCount" => total_tokens
    }
  }.to_json
end

def success_body_no_usage(text)
  {
    "candidates" => [{ "content" => { "parts" => [{ "text" => text }] } }]
  }.to_json
end

def sse_body(text, input_tokens: 10, output_tokens: 20, total_tokens: 30)
  "data: " +
    {
      "candidates" => [{ "content" => { "parts" => [{ "text" => text }] } }],
      "usageMetadata" => {
        "promptTokenCount" => input_tokens,
        "candidatesTokenCount" => output_tokens,
        "totalTokenCount" => total_tokens
      }
    }.to_json + "\n\n"
end

def interaction(url:, status:, res_body:, content_type: "application/json")
  {
    "request" => {
      "method" => "post",
      "uri" => url,
      "body" => {
        "encoding" => "UTF-8",
        "string" => ""
      },
      "headers" => {
        "Content-Type" => ["application/json"]
      }
    },
    "response" => {
      "status" => {
        "code" => status,
        "message" => ""
      },
      "headers" => {
        "Content-Type" => [content_type]
      },
      "body" => {
        "encoding" => "UTF-8",
        "string" => res_body
      }
    },
    "recorded_at" => "Wed, 04 Mar 2026 12:00:00 GMT"
  }
end

def write_cassette(name, interactions)
  path = "#{CASSETTE_DIR}/#{name}.yml"
  data = { "http_interactions" => interactions, "recorded_with" => "VCR 6.3.1" }
  File.write(path, data.to_yaml)
  puts "  #{name}.yml"
end

puts "Generating cassettes..."

url25 = gemini_url(MODEL, "generateContent")
url20 = gemini_url(MODEL_20, "generateContent")
stream25 = gemini_url(MODEL, "streamGenerateContent", extra_query: "alt=sse")
stream20 = gemini_url(MODEL_20, "streamGenerateContent", extra_query: "alt=sse")

# === GeminiClient ===
write_cassette(
  "gemini_client/generate_success",
  [
    interaction(
      url: url25,
      status: 200,
      res_body: success_body("Generated response")
    )
  ]
)
write_cassette(
  "gemini_client/generate_401",
  [interaction(url: url25, status: 401, res_body: "Unauthorized")]
)
write_cassette(
  "gemini_client/generate_403",
  [interaction(url: url25, status: 403, res_body: "Forbidden")]
)
write_cassette(
  "gemini_client/generate_429",
  [
    interaction(url: url25, status: 429, res_body: "Too many requests"),
    interaction(url: url25, status: 429, res_body: "Too many requests"),
    interaction(url: url25, status: 429, res_body: "Too many requests")
  ]
)
write_cassette(
  "gemini_client/generate_500",
  [interaction(url: url25, status: 500, res_body: "Internal Server Error")]
)
write_cassette(
  "gemini_client/generate_empty_candidates",
  [
    interaction(
      url: url25,
      status: 200,
      res_body: { "candidates" => [] }.to_json
    )
  ]
)
write_cassette(
  "gemini_client/generate_with_tokens",
  [
    interaction(
      url: url25,
      status: 200,
      res_body:
        success_body(
          "OK",
          input_tokens: 100,
          output_tokens: 50,
          total_tokens: 150
        )
    )
  ]
)
write_cassette(
  "gemini_client/generate_no_usage",
  [interaction(url: url25, status: 200, res_body: success_body_no_usage("OK"))]
)
write_cassette(
  "gemini_client/generate_ok",
  [interaction(url: url25, status: 200, res_body: success_body("OK"))]
)
write_cassette(
  "gemini_client/generate_404",
  [
    interaction(
      url: url25,
      status: 404,
      res_body: { "error" => { "message" => "Model not found" } }.to_json
    )
  ]
)
write_cassette(
  "gemini_client/generate_chat_success",
  [interaction(url: url25, status: 200, res_body: success_body("I'm great!"))]
)
write_cassette(
  "gemini_client/generate_chat_response",
  [interaction(url: url25, status: 200, res_body: success_body("Response"))]
)
write_cassette(
  "gemini_client/generate_chat_ok",
  [interaction(url: url25, status: 200, res_body: success_body("OK"))]
)
write_cassette(
  "gemini_client/stream_success",
  [
    interaction(
      url: stream25,
      status: 200,
      res_body:
        sse_body(
          "Hello world!",
          input_tokens: 5,
          output_tokens: 3,
          total_tokens: 8
        ),
      content_type: "text/event-stream"
    )
  ]
)
write_cassette(
  "gemini_client/stream_response",
  [
    interaction(
      url: stream25,
      status: 200,
      res_body:
        sse_body(
          "Response",
          input_tokens: 5,
          output_tokens: 3,
          total_tokens: 8
        ),
      content_type: "text/event-stream"
    )
  ]
)
write_cassette(
  "gemini_client/stream_logged",
  [
    interaction(
      url: stream25,
      status: 200,
      res_body:
        sse_body(
          "Streamed",
          input_tokens: 10,
          output_tokens: 5,
          total_tokens: 15
        ),
      content_type: "text/event-stream"
    )
  ]
)
write_cassette(
  "gemini_client/stream_429",
  [interaction(url: stream25, status: 429, res_body: "Rate limited")]
)
write_cassette(
  "gemini_client/stream_429_logged",
  [interaction(url: stream25, status: 429, res_body: "Too many requests")]
)
write_cassette(
  "gemini_client/stream_401",
  [interaction(url: stream25, status: 401, res_body: "Unauthorized")]
)
write_cassette(
  "gemini_client/stream_empty",
  [
    interaction(
      url: stream25,
      status: 200,
      res_body: "data: #{{ "candidates" => [] }.to_json}\n\n",
      content_type: "text/event-stream"
    )
  ]
)

# === Service tests (gemini-2.0-flash) ===
write_cassette(
  "ai_workout_feedback/chat",
  [
    interaction(
      url: url20,
      status: 200,
      res_body: success_body("Great workout!")
    )
  ]
)
write_cassette(
  "ai_workout_feedback/simple",
  [
    interaction(
      url: url20,
      status: 200,
      res_body: success_body("Basic feedback")
    )
  ]
)
write_cassette(
  "ai_workout_feedback/run",
  [interaction(url: url20, status: 200, res_body: success_body("Nice run!"))]
)
write_cassette(
  "ai_weekly_report/chat",
  [
    interaction(
      url: url20,
      status: 200,
      res_body: success_body("Weekly report")
    )
  ]
)
write_cassette(
  "ai_weekly_report/simple",
  [interaction(url: url20, status: 200, res_body: success_body("Basic report"))]
)
write_cassette(
  "ai_weekly_report/with_data",
  [interaction(url: url20, status: 200, res_body: success_body("Report"))]
)
write_cassette(
  "ai_weekly_report/no_workouts",
  [interaction(url: url20, status: 200, res_body: success_body("Report"))]
)
write_cassette(
  "ai_weekly_report/with_prs",
  [interaction(url: url20, status: 200, res_body: success_body("Report"))]
)
write_cassette(
  "ai_weekly_report/run_format",
  [interaction(url: url20, status: 200, res_body: success_body("Report"))]
)
write_cassette(
  "ai_weekly_report/russian",
  [interaction(url: url20, status: 200, res_body: success_body("Report"))]
)
write_cassette(
  "ai_weekly_report/english",
  [interaction(url: url20, status: 200, res_body: success_body("Report"))]
)
write_cassette(
  "ai_history_review/generate",
  [
    interaction(
      url: url20,
      status: 200,
      res_body: success_body("Training review content")
    )
  ]
)
write_cassette(
  "ai_history_review/with_data",
  [interaction(url: url20, status: 200, res_body: success_body("Review"))]
)
write_cassette(
  "ai_compaction/chat",
  [
    interaction(
      url: url20,
      status: 200,
      res_body: success_body("Compacted review")
    )
  ]
)

# === Job tests ===
write_cassette(
  "jobs/workout_feedback/streaming",
  [
    interaction(
      url: stream20,
      status: 200,
      res_body: sse_body("Great workout!"),
      content_type: "text/event-stream"
    )
  ]
)
write_cassette(
  "jobs/workout_feedback/simple",
  [
    interaction(
      url: url20,
      status: 200,
      res_body: success_body("Simple feedback")
    )
  ]
)
write_cassette(
  "jobs/workout_feedback/error",
  [interaction(url: stream20, status: 500, res_body: "API connection failed")]
)
write_cassette(
  "jobs/workout_feedback/new_feedback",
  [
    interaction(
      url: stream20,
      status: 200,
      res_body: sse_body("New feedback"),
      content_type: "text/event-stream"
    )
  ]
)
write_cassette(
  "jobs/workout_feedback/broadcast",
  [
    interaction(
      url: stream20,
      status: 200,
      res_body: sse_body("Streaming feedback"),
      content_type: "text/event-stream"
    )
  ]
)
write_cassette(
  "jobs/weekly_report/success",
  [
    interaction(
      url: url20,
      status: 200,
      res_body: success_body("Great progress this week!")
    )
  ]
)
write_cassette(
  "jobs/weekly_report/error",
  [
    interaction(
      url: url20,
      status: 500,
      res_body: { "error" => { "message" => "API error" } }.to_json
    )
  ]
)
write_cassette(
  "jobs/full_review/compaction",
  [interaction(url: url20, status: 200, res_body: success_body("Compacted"))]
)
write_cassette(
  "jobs/full_review/initial",
  [
    interaction(
      url: url20,
      status: 200,
      res_body: success_body("Full review content")
    )
  ]
)
write_cassette(
  "jobs/full_review/error",
  [
    interaction(
      url: url20,
      status: 500,
      res_body: { "error" => { "message" => "API error" } }.to_json
    )
  ]
)
write_cassette(
  "jobs/create_trainer/success",
  [
    interaction(
      url: url20,
      status: 200,
      res_body: success_body("Generated profile text")
    )
  ]
)
write_cassette(
  "jobs/create_trainer/error",
  [
    interaction(
      url: url20,
      status: 500,
      res_body: { "error" => { "message" => "API failure" } }.to_json
    )
  ]
)

# Routine suggestion cassettes
routine_json = {
  name: "Push Pull Legs Routine",
  days: [
    {
      name: "Push Day",
      exercises: [
        { name: "Bench Press", muscle: "chest" },
        { name: "Tricep Extension", muscle: "triceps" }
      ]
    },
    {
      name: "Pull Day",
      exercises: [
        { name: "Deadlift", muscle: "back" },
        { name: "Pull-Up", muscle: "back" },
        { name: "Bicep Curl", muscle: "biceps" }
      ]
    },
    { name: "Leg Day", exercises: [{ name: "Squat", muscle: "legs" }] }
  ]
}.to_json
write_cassette(
  "jobs/routine_suggestion/success",
  [interaction(url: url20, status: 200, res_body: success_body(routine_json))]
)
write_cassette(
  "jobs/routine_suggestion/simple",
  [interaction(url: url20, status: 200, res_body: success_body(routine_json))]
)
write_cassette(
  "jobs/routine_suggestion/comments",
  [
    interaction(
      url: url20,
      status: 200,
      res_body:
        success_body(
          {
            name: "Commented Routine",
            days: [
              {
                name: "Day 1",
                exercises: [
                  {
                    name: "Bench Press",
                    muscle: "chest",
                    comment: "focus on form"
                  },
                  { name: "Squat", muscle: "legs" }
                ]
              }
            ]
          }.to_json
        )
    )
  ]
)
write_cassette(
  "jobs/routine_suggestion/superset_comments",
  [
    interaction(
      url: url20,
      status: 200,
      res_body:
        success_body(
          {
            name: "Superset Comment Routine",
            days: [
              {
                name: "Day 1",
                exercises: [
                  {
                    superset: "Chest/Back Superset",
                    comment: "no rest between exercises",
                    exercises: [
                      { name: "Bench Press", muscle: "chest" },
                      { name: "Deadlift", muscle: "back" }
                    ]
                  }
                ]
              }
            ]
          }.to_json
        )
    )
  ]
)
write_cassette(
  "jobs/routine_suggestion/new_exercise",
  [
    interaction(
      url: url20,
      status: 200,
      res_body:
        success_body(
          {
            name: "Test Routine",
            days: [
              {
                name: "Day 1",
                exercises: [{ name: "Overhead Press", muscle: "shoulders" }]
              }
            ]
          }.to_json
        )
    )
  ]
)
write_cassette(
  "jobs/routine_suggestion/invalid_muscle",
  [
    interaction(
      url: url20,
      status: 200,
      res_body:
        success_body(
          {
            name: "Test Routine",
            days: [
              {
                name: "Day 1",
                exercises: [
                  { name: "Bench Press", muscle: "chest" },
                  { name: "Magic Lift", muscle: "nonexistent_muscle" }
                ]
              }
            ]
          }.to_json
        )
    )
  ]
)
write_cassette(
  "jobs/routine_suggestion/superset",
  [
    interaction(
      url: url20,
      status: 200,
      res_body:
        success_body(
          {
            name: "Superset Routine",
            days: [
              {
                name: "Day 1",
                exercises: [
                  {
                    superset: "Chest/Back Superset",
                    exercises: [
                      { name: "Bench Press", muscle: "chest" },
                      { name: "Deadlift", muscle: "back" }
                    ]
                  }
                ]
              }
            ]
          }.to_json
        )
    )
  ]
)
write_cassette(
  "jobs/routine_suggestion/reuse_superset",
  [
    interaction(
      url: url20,
      status: 200,
      res_body:
        success_body(
          {
            name: "Reuse Routine",
            days: [
              {
                name: "Day 1",
                exercises: [
                  {
                    superset: "Push Pull",
                    exercises: [
                      { name: "Bench Press", muscle: "chest" },
                      { name: "Pull-Up", muscle: "back" }
                    ]
                  }
                ]
              }
            ]
          }.to_json
        )
    )
  ]
)
write_cassette(
  "jobs/routine_suggestion/new_superset",
  [
    interaction(
      url: url20,
      status: 200,
      res_body:
        success_body(
          {
            name: "New Superset Routine",
            days: [
              {
                name: "Day 1",
                exercises: [
                  {
                    superset: "Shoulder Combo",
                    exercises: [
                      { name: "Lateral Raise", muscle: "shoulders" },
                      { name: "Front Raise", muscle: "shoulders" }
                    ]
                  }
                ]
              }
            ]
          }.to_json
        )
    )
  ]
)
write_cassette(
  "jobs/routine_suggestion/recommendations",
  [
    interaction(
      url: url20,
      status: 200,
      res_body:
        success_body(
          {
            name: "Recommended Routine",
            days: [
              {
                name: "Day 1",
                notes: "Focus on chest and triceps",
                exercises: [
                  {
                    name: "Bench Press",
                    muscle: "chest",
                    sets: "3-4",
                    reps: "8-12",
                    min_rest: 60,
                    max_rest: 90,
                    comment: "control the descent"
                  },
                  {
                    name: "Squat",
                    muscle: "legs",
                    sets: "4",
                    reps: "6-8",
                    min_rest: 90,
                    max_rest: 120
                  }
                ]
              }
            ]
          }.to_json
        )
    )
  ]
)
write_cassette(
  "jobs/routine_suggestion/superset_recommendations",
  [
    interaction(
      url: url20,
      status: 200,
      res_body:
        success_body(
          {
            name: "Superset Rec Routine",
            days: [
              {
                name: "Day 1",
                exercises: [
                  {
                    superset: "Chest/Back Superset",
                    sets: "3",
                    reps: "10-12",
                    min_rest: 30,
                    max_rest: 60,
                    comment: "no rest between exercises",
                    exercises: [
                      { name: "Bench Press", muscle: "chest" },
                      { name: "Deadlift", muscle: "back" }
                    ]
                  }
                ]
              }
            ]
          }.to_json
        )
    )
  ]
)
write_cassette(
  "jobs/routine_suggestion/error",
  [
    interaction(
      url: url20,
      status: 500,
      res_body: { "error" => { "message" => "API error" } }.to_json
    )
  ]
)

# === AI Followup Job ===
write_cassette(
  "jobs/followup/basic",
  [
    interaction(
      url: stream20,
      status: 200,
      res_body:
        sse_body(
          "Yes, you should increase weight by 2.5kg next session.",
          input_tokens: 50,
          output_tokens: 15,
          total_tokens: 65
        ),
      content_type: "text/event-stream"
    )
  ]
)
write_cassette(
  "jobs/followup/with_history",
  [
    interaction(
      url: stream20,
      status: 200,
      res_body:
        sse_body(
          "Based on our previous discussion, here's more detail.",
          input_tokens: 80,
          output_tokens: 20,
          total_tokens: 100
        ),
      content_type: "text/event-stream"
    )
  ]
)
write_cassette(
  "jobs/followup/broadcast",
  [
    interaction(
      url: stream20,
      status: 200,
      res_body:
        sse_body(
          "Your form looked good overall.",
          input_tokens: 50,
          output_tokens: 10,
          total_tokens: 60
        ),
      content_type: "text/event-stream"
    )
  ]
)

# === AI Memory Extraction ===
embed_url20 = gemini_url("gemini-embedding-001", "embedContent")
fake_embedding = Array.new(768) { |i| (Math.sin(i) * 0.1).round(6) }

def embedding_body(values)
  { "embedding" => { "values" => values } }.to_json
end

write_cassette(
  "ai_memory_extraction/success",
  [
    interaction(
      url: url20,
      status: 200,
      res_body:
        success_body(
          "[schedule]|6|Trains mostly on weekday evenings\n[equipment]|7|Uses barbells and dumbbells regularly"
        )
    ),
    interaction(
      url: embed_url20,
      status: 200,
      res_body: embedding_body(fake_embedding)
    ),
    interaction(
      url: embed_url20,
      status: 200,
      res_body: embedding_body(fake_embedding)
    )
  ]
)
write_cassette(
  "ai_memory_extraction/none",
  [interaction(url: url20, status: 200, res_body: success_body("NONE"))]
)
write_cassette(
  "ai_memory_extraction/duplicate",
  [
    interaction(
      url: url20,
      status: 200,
      res_body: success_body("[schedule]|6|Typically trains 3-4 times per week")
    )
  ]
)
write_cassette(
  "ai_memory_extraction/replacement",
  [
    interaction(
      url: url20,
      status: 200,
      res_body:
        success_body(
          "REPLACES: Typically trains 3-4 times per week|[schedule]|6|Trains 4-5 times per week now"
        )
    ),
    interaction(
      url: embed_url20,
      status: 200,
      res_body: embedding_body(fake_embedding)
    )
  ]
)
write_cassette(
  "ai_memory_extraction/invalid_category",
  [
    interaction(
      url: url20,
      status: 200,
      res_body: success_body("[invalid_cat]|5|Some observation")
    )
  ]
)
write_cassette(
  "ai_memory_extraction/bootstrap",
  [
    interaction(
      url: url20,
      status: 200,
      res_body:
        success_body(
          "[schedule]|6|Trains on Monday, Wednesday, and Friday evenings\n[preferences]|5|Prefers compound movements like bench press and squats"
        )
    ),
    interaction(
      url: embed_url20,
      status: 200,
      res_body: embedding_body(fake_embedding)
    ),
    interaction(
      url: embed_url20,
      status: 200,
      res_body: embedding_body(fake_embedding)
    )
  ]
)

# === Embedding ===
write_cassette(
  "embedding/success",
  [
    interaction(
      url: embed_url20,
      status: 200,
      res_body: embedding_body(fake_embedding)
    )
  ]
)

puts "\nDone! #{Dir.glob("#{CASSETTE_DIR}/**/*.yml").count} cassettes."
