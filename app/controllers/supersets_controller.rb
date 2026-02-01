class SupersetsController < ApplicationController
  before_action :set_superset, only: %i[show edit update destroy]

  def index
    @supersets = Current.user.supersets.order(name: :asc)
  end

  def show
  end

  def new
    @superset = Current.user.supersets.new
  end

  def edit
  end

  def create
    @superset = Current.user.supersets.new(superset_params)

    respond_to do |format|
      if @superset.save
        format.html do
          redirect_to @superset, notice: I18n.t("controllers.supersets.created")
        end
        format.json { render :show, status: :created, location: @superset }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json do
          render json: @superset.errors, status: :unprocessable_entity
        end
      end
    end
  end

  def update
    respond_to do |format|
      if @superset.update(superset_params)
        format.html do
          redirect_to @superset, notice: I18n.t("controllers.supersets.updated")
        end
        format.json { render :show, status: :ok, location: @superset }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json do
          render json: @superset.errors, status: :unprocessable_entity
        end
      end
    end
  end

  def destroy
    @superset.destroy!

    respond_to do |format|
      format.html do
        redirect_to supersets_path,
                    status: :see_other,
                    notice: I18n.t("controllers.supersets.destroyed")
      end
      format.json { head :no_content }
    end
  end

  private

  def set_superset
    @superset = Current.user.supersets.find(params.expect(:id))
  end

  def superset_params
    params.expect(superset: [:name])
  end
end
