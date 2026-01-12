class StatsController < ApplicationController
  def index
    @hours_per_week = hours_per_week_data
    @distance_per_week = distance_per_week_data
    @workouts_per_week = workouts_per_week_data
  end

  private

  def hours_per_week_data
    workouts = Current.user.workouts.where.not(time_in_seconds: nil)
    return { labels: [], data: [] } if workouts.empty?

    grouped = workouts.group_by { |w| w.started_at.beginning_of_week.to_date }
    sorted_weeks = grouped.keys.sort

    labels = sorted_weeks.map { |w| w.strftime("%b %d") }
    data = sorted_weeks.map { |w| (grouped[w].sum(&:time_in_seconds) / 3600.0).round(2) }

    { labels: labels, data: data }
  end

  def distance_per_week_data
    runs = Current.user.workouts.run.where.not(distance: nil)
    return { labels: [], data: [] } if runs.empty?

    grouped = runs.group_by { |r| r.started_at.beginning_of_week.to_date }
    sorted_weeks = grouped.keys.sort

    labels = sorted_weeks.map { |w| w.strftime("%b %d") }
    data = sorted_weeks.map { |w| (grouped[w].sum(&:distance) / 1000.0).round(2) }

    { labels: labels, data: data }
  end

  def workouts_per_week_data
    workouts = Current.user.workouts.where.not(ended_at: nil)
    return { labels: [], data_strength: [], data_runs: [] } if workouts.empty?

    strength_grouped = workouts.strength.group_by { |w| w.started_at.beginning_of_week.to_date }
    runs_grouped = workouts.run.group_by { |w| w.started_at.beginning_of_week.to_date }

    all_weeks = (strength_grouped.keys + runs_grouped.keys).uniq.sort

    labels = all_weeks.map { |w| w.strftime("%b %d") }
    data_strength = all_weeks.map { |w| strength_grouped[w]&.count || 0 }
    data_runs = all_weeks.map { |w| runs_grouped[w]&.count || 0 }

    { labels: labels, data_strength: data_strength, data_runs: data_runs }
  end
end
