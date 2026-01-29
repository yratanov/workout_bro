module WorkoutRepsHelper
  def weight_options(user)
    (user.weight_min..user.weight_max)
      .step(user.weight_step)
      .map { |w| ["#{w}#{user.weight_unit}", w] }
  end
end
