require_relative 'helper'

after 'development:target_groups', 'development:faculty' do
  puts 'Seeding targets'

  video_embed = '<iframe width="560" height="315" src="https://www.youtube.com/embed/58CPRi5kRe8" frameborder="0" allowfullscreen></iframe>'

  def paragraph
    Faker::Lorem.paragraphs.join("\n\n")
  end

  def session_taker_name
    Faker::Name.name
  end

  faculty_1 = Faculty.first
  faculty_2 = Faculty.second

  # Level 0 target group
  level_0_target_group = Level.find_by(number: 0).target_groups.find_by(milestone: false)

  # Compulsory Level 0 targets.
  level_0_milestone_group = Level.find_by(number: 0).target_groups.find_by(milestone: true)

  # Screening target.
  screening_target = Target.create!(days_to_complete: 1, title: 'Go through Screening', role: Target::ROLE_TEAM, submittability: Target::SUBMITTABILITY_SUBMITTABLE_ONCE, link_to_complete: '/admissions/screening', key: Target::KEY_SCREENING, target_group: level_0_target_group, description: paragraph, faculty: faculty_1, target_action_type: Target::TYPE_TODO)

  # Cofounder addition target.
  Target.create!(days_to_complete: 1, title: 'Add team members', role: Target::ROLE_TEAM, link_to_complete: '/admissions/team_members', key: Target::KEY_COFOUNDER_ADDITION, target_group: level_0_target_group, description: paragraph, prerequisite_targets: [screening_target], faculty: faculty_1, target_action_type: Target::TYPE_TODO)

  # Showcase previous work target.
  Target.create!(days_to_complete: 1, title: 'Showcase previous work', role: Target::ROLE_TEAM,key: Target::KEY_R1_SHOW_PREVIOUS_WORK, target_group: level_0_target_group, description: paragraph, prerequisite_targets: [screening_target], faculty: faculty_1, target_action_type: Target::TYPE_TODO)

  # Round 1 coding task.
  Target.create!(days_to_complete: 1, title: 'Round 1 Coding Task', role: Target::ROLE_TEAM,key: Target::KEY_R1_TASK, target_group: level_0_target_group, description: paragraph, prerequisite_targets: [screening_target], faculty: faculty_1, target_action_type: Target::TYPE_TODO, submittability: Target::SUBMITTABILITY_AUTO_VERIFY)

  # Round 2 coding task.
  round_two_coding_task = Target.create!(days_to_complete: 1, title: 'Round 2 Coding Task', role: Target::ROLE_TEAM, key: Target::KEY_R2_TASK, target_group: level_0_milestone_group, description: paragraph, prerequisite_targets: [screening_target], faculty: faculty_1, target_action_type: Target::TYPE_TODO)

  # Interview target.
  interview_target = Target.create!(days_to_complete: 1, title: 'Attend SV.CO Interview', role: Target::ROLE_TEAM, key: Target::KEY_ATTEND_INTERVIEW, target_group: level_0_milestone_group, description: paragraph, prerequisite_targets: [screening_target, round_two_coding_task], faculty: faculty_1, target_action_type: Target::TYPE_TODO)

  # Fee payment target.
  Target.create!(days_to_complete: 1, title: 'Pay Admission Fee', role: Target::ROLE_TEAM, submittability: Target::SUBMITTABILITY_SUBMITTABLE_ONCE, link_to_complete: '/founder/fee', key: Target::KEY_FEE_PAYMENT, target_group: level_0_milestone_group, description: paragraph, prerequisite_targets: [screening_target, interview_target], faculty: faculty_2, target_action_type: Target::TYPE_TODO)

  # Random targets and sessions for every level.
  Level.where.not(number: 0).each do |level|

    # Two vanilla targets and one session per target_group.
    level.target_groups.each do |target_group|
      # Targets.
      2.times do
        target_group.targets.create!(days_to_complete: [7, 10, 14].sample, title: Faker::Lorem.sentence, role: Target.valid_roles.sample, target_group: target_group, description: paragraph, faculty: faculty_1, target_action_type: Target::TYPE_TODO)
      end

      # Session.
      target_group.targets.create!(title: Faker::Lorem.sentence, role: Target.valid_roles.sample, session_at: 1.month.ago, description: paragraph, session_by: session_taker_name, video_embed: video_embed, target_action_type: Target::TYPE_ATTEND)
    end
  end
end
