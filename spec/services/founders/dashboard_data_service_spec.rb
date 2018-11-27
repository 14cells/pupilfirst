require 'rails_helper'

describe Founders::DashboardDataService do
  subject { described_class.new(founder) }

  let(:course_1) { create :course }
  let(:course_2) { create :course }
  let!(:level_0) { create :level, :zero, course: course_1 }
  let!(:level_1) { create :level, :one, course: course_1 }
  let!(:level_2) { create :level, :two, course: course_1 }
  let!(:unlocked_level_3) { create :level, :three, course: course_1, unlock_on: 1.month.ago }
  let!(:locked_level_4) { create :level, :four, course: course_1, unlock_on: 1.month.from_now }
  let(:course_2_level) { create :level, :one, course: course_2 }
  let!(:startup) { create :startup, level: level_0 }
  let!(:founder) { create :founder, startup: startup }
  let!(:track_1) { create :track }
  let!(:track_2) { create :track }
  let!(:target_group_l0_1) { create :target_group, level: level_0, milestone: true }
  let!(:target_group_l0_2) { create :target_group, level: level_0 }
  let!(:target_group_l1_1) { create :target_group, level: level_1, milestone: true, track: track_1 }
  let!(:target_group_l1_2) { create :target_group, level: level_1, track: track_2 }
  let!(:target_group_l2_1) { create :target_group, level: level_2, milestone: true, track: track_1 }
  let!(:target_group_l2_2) { create :target_group, level: level_2, track: track_2 }
  let!(:target_group_l3_1) { create :target_group, level: unlocked_level_3, track: track_1 }
  let!(:target_group_l4_1) { create :target_group, level: locked_level_4, track: track_1 }
  let(:course_2_target_group) { create :target_group, level: course_2_level }
  let!(:course_2_target) { create :target, target_group: course_2_target_group }
  let!(:level_0_target) { create :target, target_group: target_group_l0_1 }
  let!(:level_0_session) { create :target, session_at: 1.day.ago, target_group: target_group_l0_2 }
  let!(:level_1_target) { create :target, target_group: target_group_l1_1 }
  let!(:level_1_session) { create :target, session_at: 1.day.ago, target_group: target_group_l1_2 }
  let!(:level_2_target) { create :target, target_group: target_group_l2_2 }
  let!(:level_2_session) { create :target, session_at: 1.day.ago, target_group: target_group_l2_2 }
  let!(:level_2_target_with_prerequisites) { create :target, target_group: target_group_l2_1, prerequisite_targets: [level_2_target, level_2_session] }
  let!(:level_3_target) { create :target, target_group: target_group_l3_1 }
  let!(:level_4_target) { create :target, target_group: target_group_l4_1 }

  describe '#props' do
    context 'when startup is in level 0' do
      it 'restricts data to level 0' do
        expected_target_groups = [
          hash_including(target_group_l0_1.slice(target_group_fields).merge(level: { id: level_0.id })),
          hash_including(target_group_l0_2.slice(target_group_fields).merge(level: { id: level_0.id }))
        ]

        expected_targets = [
          hash_including(level_0_target.slice(target_fields).merge(additional_target_fields(level_0_target, target_group_l0_1))),
          hash_including(level_0_session.slice(target_fields).merge(additional_target_fields(level_0_session, target_group_l0_2)))
        ]

        team_members = Faculty.team.all.as_json(only: %i[id name], methods: %i[image_url]).map do |faculty_fields|
          hash_including(faculty_fields)
        end

        props = subject.props

        expect(props.keys).to contain_exactly(:faculty, :levels, :targetGroups, :targets, :tracks)
        expect(props[:faculty]).to contain_exactly(*team_members)
        expect(props[:levels]).to contain_exactly(*level_fields(level_0))
        expect(props[:targetGroups]).to contain_exactly(*expected_target_groups)
        expect(props[:targets]).to contain_exactly(*expected_targets)
        expect(props[:tracks]).to contain_exactly(*track_fields(track_1, track_2))
      end
    end

    context 'when startup is in level N > 1' do
      let(:startup) { create :startup, level: level_2 }

      it 'leaves out data from level 0, and includes data from all open 1+ levels' do
        expected_target_groups = [
          hash_including(target_group_l1_1.slice(target_group_fields).merge(track: { id: track_1.id }, level: { id: level_1.id })),
          hash_including(target_group_l1_2.slice(target_group_fields).merge(track: { id: track_2.id }, level: { id: level_1.id })),
          hash_including(target_group_l2_1.slice(target_group_fields).merge(track: { id: track_1.id }, level: { id: level_2.id })),
          hash_including(target_group_l2_2.slice(target_group_fields).merge(track: { id: track_2.id }, level: { id: level_2.id })),
          hash_including(target_group_l3_1.slice(target_group_fields).merge(track: { id: track_1.id }, level: { id: unlocked_level_3.id }))
        ]

        expected_targets = [
          hash_including(level_1_target.slice(target_fields).merge(additional_target_fields(level_1_target, target_group_l1_1))),
          hash_including(level_1_session.slice(target_fields).merge(additional_target_fields(level_1_session, target_group_l1_2))),
          hash_including(level_2_target.slice(target_fields).merge(additional_target_fields(level_2_target, target_group_l2_2))),
          hash_including(level_2_session.slice(target_fields).merge(additional_target_fields(level_2_session, target_group_l2_2))),
          hash_including(level_2_target_with_prerequisites.slice(target_fields).merge(additional_target_fields(level_2_target_with_prerequisites, target_group_l2_1, :pending_milestone)).merge(prerequisite_fields(level_2_target_with_prerequisites))),
          hash_including(level_3_target.slice(target_fields).merge(additional_target_fields(level_3_target, target_group_l3_1, :level_locked)))
        ]

        team_members = Faculty.team.all.as_json(only: %i[id name], methods: %i[image_url]).map do |faculty_fields|
          hash_including(faculty_fields)
        end

        props = subject.props

        expect(props.keys).to contain_exactly(:faculty, :levels, :targetGroups, :targets, :tracks)
        expect(props[:faculty]).to contain_exactly(*team_members)
        expect(props[:levels]).to contain_exactly(*level_fields(level_1, level_2, unlocked_level_3, locked_level_4))
        expect(props[:targetGroups]).to contain_exactly(*expected_target_groups)
        expect(props[:targets]).to contain_exactly(*expected_targets)
        expect(props[:tracks]).to contain_exactly(*track_fields(track_1, track_2))
      end
    end
  end

  def level_fields(*levels)
    levels.map do |level|
      hash_including(level.slice(:id, :name, :number))
    end
  end

  def track_fields(*tracks)
    tracks.map do |track|
      hash_including(track.slice(:id, :name, :sort_index))
    end
  end

  def prerequisite_fields(target)
    { prerequisites: target.prerequisite_targets.map { |t| { id: t.id } } }
  end

  def target_group_fields
    %i[id name description sort_index milestone]
  end

  def additional_target_fields(target, target_group, status = :pending)
    fields = {
      target_group: { id: target_group.id },
      faculty: { id: target.faculty.id },
      status: status,
      prerequisites: []
    }

    return fields if target.session_at.blank?

    fields.merge(session_at: a_value_within(1.second).of(target.session_at))
  end

  def target_fields
    %i[id role title description completion_instructions resource_url slideshow_embed days_to_complete points_earnable sort_index video_embed link_to_complete submittability archived youtube_video_id call_to_action]
  end
end
