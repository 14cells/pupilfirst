ActiveAdmin.register QuizQuestion do
  include DisableIntercom

  menu parent: 'SixWays'
  permit_params :course_module_id, :question, answer_options_attributes: [:id, :value, :correct_answer, :hint_text, :_destroy]

  index do
    selectable_column
    column :question
    column :correct_answer do |question|
      question.correct_answer.value if question.correct_answer.present?
    end
    column :course_module_id
    actions
  end

  form do |f|
    f.semantic_errors

    # TODO: Reduce height of the text field below. 'input_html' seems to be malfunctioning
    f.inputs 'Question Details' do
      f.input :question
      f.input :course_module
    end

    f.inputs 'Answer Options' do
      f.has_many :answer_options, heading: false, allow_destroy: true, new_record: 'Add Option' do |o|
        o.input :value
        o.input :correct_answer
        o.input :hint_text
      end
    end
    f.actions
  end

  show do
    attributes_table do
      row :question
      row :course_module_id
      row :correct_answer do |question|
        question.correct_answer.value if question.correct_answer.present?
      end
      row :answer_options do |question|
        question.answer_options.pluck(:value).join(', ')
      end
    end
  end
end
