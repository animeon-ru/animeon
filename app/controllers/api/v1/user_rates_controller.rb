class Api::V1::UserRatesController < Api::V1Controller
  UPDATE_PARAMS = %i[
    score status episodes
  ]

  api :PUT, '/api/v1/user_rates/:id', 'Update a user rate'
  api :PATCH, '/api/v1/user_rates/:id', 'Update a user rate'
  def update
    @user_rate = UserRate.find(params[:id])
    if @user_rate.update(update_params)
      render json: { user_rate: @user_rate }, status: 200
    else
      render json: { errors: @user_rate.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private
  def update_params
    params.require(:user_rate).permit(*UPDATE_PARAMS)
  end
end
