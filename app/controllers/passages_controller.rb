class PassagesController < ApplicationController
  helper PassagesHelper

  layout false, except: [:index, :edit]

  before_action :verify_privileges, only: [:drafts, :opened, :closed]
  before_action :set_active_tab_and_redirect, only: [:new, :drafts, :closed, :opened, :open_for_candidate, :missed_by_candidate, :attempted_by_candidate]

  NEW = 'new'
  SAVED = 'drafts'
  OPENED = 'ongoing'
  COMMENCED = 'commenced'
  MISSED = 'missed'
  ATTEMPTED = 'attempted'
  CLOSED = 'finished'


  ALL_TABS = {
      new: NEW,
      drafts: SAVED,
      opened: OPENED,
      closed: CLOSED,
      open_for_candidate: COMMENCED,
      missed_by_candidate: MISSED,
      attempted_by_candidate: ATTEMPTED
  }

  def default_tab
    current_user.admin ? OPENED : COMMENCED
  end

  def new
    @passage = Passage.new
  end

  def edit
    @passage = Passage.find(params[:id])
    render :new
  end

  def index
    @passages = Passage.all
    render :index, locals: {active_tab: current_tab}
  end

  def update
    passage = Passage.find(params[:id])

    respond_to do |format|
      if passage.update_attributes(permit_params)
        flash[:success] = 'Passage was successfully updated...'
        format.html { redirect_to passages_path }
      else
        flash_error(passage)
        format.html { redirect_to edit_passage_path }
      end
    end
  end

  def create
    passage = Passage.new(permit_params)

    respond_to do |format|
      if passage.save
        flash[:success] = 'Passage was successfully created.'
        format.html { redirect_to passages_path }
      else
        flash_error(passage)
        format.html { redirect_to new_passage_path }
      end
    end
  end

  def destroy
    Passage.find(params[:id]).destroy
    redirect_to :passages
  end

  def roll_out
    close_time = params[:passage][:close_time]
    Passage.find(params[:id]).roll_out(close_time)
    redirect_to :passages
  end

  def close
    Passage.find(params[:id]).close
    redirect_to :passages
  end

  #TODO all the passage getter methods should give out json if asked for

  def drafts
    filtered_passages = Passage.draft_passages
    render "passages/admin/passages_pane", locals: {filtered_passages: filtered_passages, partial_name: "drafts_passages"}
  end

  def opened
    filtered_passages = Passage.open_passages
    render "passages/admin/passages_pane", locals: {filtered_passages: filtered_passages, partial_name: "opened_passages"}
  end

  def closed
    filtered_passages = Passage.closed_passages
    render "passages/admin/passages_pane", locals: {filtered_passages: filtered_passages, partial_name: "closed_passages"}
  end

  def open_for_candidate
    filtered_passages = Passage.open_for_candidate(current_user)
    render "passages/candidate/passages_pane", locals: {filtered_passages: filtered_passages, partial_name: "opened_passages"}
  end

  def missed_by_candidate
    filtered_passages = Passage.missed_by_candidate(current_user)
    render "passages/candidate/passages_pane", locals: {filtered_passages: filtered_passages, partial_name: "missed_passages"}
  end

  def attempted_by_candidate
    passages = Passage.attempted_by_candidate(current_user)
    render "passages/candidate/attempted_passages_pane", locals: {filtered_passages: passages}
  end

  private

  def from_tab?
    params[:from_tab].eql? 'true'
  end

  def set_active_tab_and_redirect
    set_current_tab ALL_TABS[params[:action].to_sym]
    redirect_to passages_path unless from_tab?
  end

  def verify_privileges
    unless current_user.admin
      set_current_tab default_tab
      flash[:danger] = "Either the resource you have requested does not exist or you don't have access to them"
      redirect_to passages_path
    end
  end

  def permit_params
    params.require("passage").permit(:title, :text, :duration, :start_time, :close_time)
  end

  def flash_error(passage)
    flash[:danger] = passage.errors.messages.map do |m|
      m.join(' ').humanize
    end.join("\n")
  end

end
