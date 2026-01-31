module PersonalRecordsHelper
  def pr_type_badge_class(pr_type)
    case pr_type.to_s
    when "max_weight"
      "bg-yellow-600/20 text-yellow-400"
    when "max_volume"
      "bg-green-600/20 text-green-400"
    when "max_reps"
      "bg-blue-600/20 text-blue-400"
    else
      "bg-slate-600/20 text-slate-400"
    end
  end
end
