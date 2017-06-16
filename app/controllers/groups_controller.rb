class GroupsController < ApplicationController
  helper_method :xeditable?

  before_action :verify_privileges, only: [:index, :create]
  before_action :set_group, only: [:show, :edit, :update, :destroy]
  layout false, only: [:new, :edit, :create, :destroy]

  def new
    @group = Group.new
  end


  def index
    @groups = Group.all.order('name ASC')
  end

  def update
    @group.update(group_params)
  end

  def create
    @group = Group.new(group_params)

    respond_to do |format|
      format.html do
        if @group.save
          flash[:success] = "Group #{@group.name} was successfully created."
        else
          error = @group.errors.messages
          flash[:danger] = "name #{error[:name].first}"
        end
        redirect_to groups_path
      end
    end
  end

  def destroy
    @group.destroy
    respond_to do |format|
      flash[:danger] = "Group #{@group.name} was successfully deleted."
      format.html {redirect_to groups_path}
      format.json {head :no_content}
    end
  end

  def xeditable? object = nil
    true # Or something like current_user.xeditable?
  end

  private

  def set_group
    @group = Group.find(params[:id])
  end

  def group_params
    params.require("group").permit(:name, :description)
  end

end