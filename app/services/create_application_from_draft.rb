# frozen_string_literal: true
class CreateApplicationFromDraft
  PROJECT_FIELDS = ApplicationDraft::PROJECT_FIELDS.map(&:to_s)
  STUDENT_FIELDS = [0, 1].map { |index| User.columns.map(&:name).select{ |n| /\Aapplication_/ =~ n }.map{|n| "student#{index}_#{n}" } }.flatten

  def initialize(application_draft)
    @application_draft = application_draft
  end

  def call
    application.save
  end

  private

  attr_reader :application_draft

  def team
    @team ||= application_draft.team
  end

  def application
    @application ||= Application.new(application_attributes)
  end

  def application_attributes
    {
      team: team,
      team_snapshot: team_snapshot,
      application_draft: application_draft,
      application_data: application_data,
      season: application_draft.season,
    }
  end

  private

  def application_data
    {
      work_weeks: application_draft.work_weeks,
      work_week_explanation: application_draft.work_week_explanation,
      heard_about_it: application_draft.heard_about_it,
      misc_info: application_draft.misc_info,
      working_together: application_draft.working_together,
      why_selected_project1: application_draft.why_selected_project1
    }.merge(student_attributes).merge(project_attributes)
  end

  def project_attributes
    PROJECT_FIELDS.each_with_object({}) do |attribute, hash|
      hash[attribute] = application_draft.send(attribute)
    end
  end

  def student_attributes
    STUDENT_FIELDS.each_with_object({}) do |attribute, hash|
      hash[attribute] = application_draft.send(attribute)
    end
  end

  class TeamSnapshot < Struct.new(:team)
    def to_hash
      %w(students coaches mentors).each_with_object({}) do |list, hash|
        hash[list] = team.send(list).map { |u| [u.name, u.email] }
      end
    end
  end

  def team_snapshot
    TeamSnapshot.new(team || Team.new).to_hash
  end
end