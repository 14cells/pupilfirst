module Targets
  class OverlayDetailsService
    def initialize(target, founder)
      @target = target
      @founder = founder
    end

    def all_details
      {
        founderStatuses: founder_statuses,
        latestEvent: latest_event_details,
        latestFeedback: latest_feedback,
        linkedResources: linked_resources,
        quizQuestions: quiz_questions
      }
    end

    private

    def founder_statuses
      return nil unless @target.founder_role?

      @founder.startup.founders.not_exited.map do |founder|
        {
          id: founder.id,
          status: Targets::StatusService.new(@target, founder).status
        }
      end
    end

    def latest_event_details
      return nil if latest_event.blank?

      {
        description: latest_event.description,
        event_on: latest_event.event_on,
        title: latest_event.title,
        days_elapsed: latest_event.days_elapsed,
        attachments: latest_event_attachments
      }
    end

    def latest_event
      @latest_event ||= @target.latest_linked_event(@founder)
    end

    def latest_feedback
      Targets::FeedbackService.new(@target, @founder).latest_feedback_details
    end

    def latest_event_attachments
      return nil if latest_event.blank?

      attachments = latest_event.timeline_event_files.each_with_object([]) do |file, array|
        array << { type: "file", title: file.title, url: file.file_url }
      end

      latest_event.links.each_with_object(attachments) do |link, array|
        array << { type: "link", title: link[:title], url: link[:url] }
      end
    end

    def linked_resources
      return if @target.resources.blank?

      @target.resources.map do |resource|
        {
          id: resource.id,
          title: resource.title,
          slug: resource.slug,
          canStream: resource.stream?,
          hasLink: resource.link.present?,
          hasFile: resource.file.present?
        }
      end
    end

    def quiz_questions
      return if @target.quiz.blank?

      @target.quiz.quiz_questions.each_with_index.map do |question, index|
        {
          index: index,
          question: question.question,
          description: question.description,
          correct_answer_id: question.correct_answer_id,
          answer_options: answer_options(question)
        }
      end
    end

    def answer_options(question)
      question.answer_options.map do |answer|
        {
          id: answer.id,
          value: answer.value,
          hint: answer.hint
        }
      end
    end
  end
end
