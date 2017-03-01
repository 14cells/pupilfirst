class TeamMembersController < ApplicationController
  before_action :authenticate_founder!

  # GET /founder/startup/team_members/new
  def new
    @team_members = current_founder.startup.team_members
    @team_member =  TeamMember.new(startup: current_founder.startup)
    render 'create_or_edit'
  end

  # POST /founder/startup/team_members
  def create
    @team_members = current_founder.startup.team_members
    @team_member = TeamMember.new team_member_params.merge(startup: current_founder.startup)

    if @team_member.save
      flash[:success] = 'Added new team member!'
      redirect_to edit_founder_startup_url
    else
      flash.now[:error] = 'Could not create new team member.'
      render 'create_or_edit'
    end
  end

  # GET /founder/startup/team_members/:id
  def edit
    @team_members = current_founder.startup.team_members
    @team_member = @team_members.find(params[:id])
    render 'create_or_edit'
  end

  # PATCH /founder/startup/team_members/:id
  def update
    @team_members = current_founder.startup.team_members
    @team_member = @team_members.find(params[:id])

    if @team_member.update(team_member_params)
      flash[:success] = 'Updated team member!'
      redirect_to edit_founder_startup_url
    else
      flash.now[:error] = 'Could not update team member.'
      render 'create_or_edit'
    end
  end

  # DELETE /founder/startup/team_members/:id
  def destroy
    @team_members = current_founder.startup.team_members
    @team_member = @team_members.find(params[:id])

    if @team_member.destroy
      flash[:success] = 'Deleted team member!'
      redirect_to edit_founder_startup_url
    else
      flash[:error] = 'Could not delete team member.'
      render 'create_or_edit'
    end
  end

  private

  def team_member_params
    params.require(:team_member).permit(:name, :email, :avatar, roles: [])
  end
end
