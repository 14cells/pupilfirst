ActiveAdmin.register Startup do
  include DisableIntercom

  permit_params :product_name, :product_description, :legal_registered_name, :website, :email, :logo, :facebook_link,
    :twitter_link, :created_at, :updated_at, :dropped_out, :registration_type, :agreement_signed_at,
    :presentation_link, :product_video_link, :wireframe_link, :prototype_link, :slug, :batch_id,
    startup_category_ids: [], founder_ids: [], tag_list: []

  filter :product_name, as: :select
  filter :batch
  filter :stage, as: :select, collection: proc { stages_collection }

  filter :ransack_tagged_with,
    as: :select,
    multiple: true,
    label: 'Tags',
    collection: -> { Startup.tag_counts_on(:tags).pluck(:name).sort }

  filter :legal_registered_name
  filter :website
  filter :registration_type, as: :select, collection: proc { Startup.valid_registration_types }
  filter :startup_categories
  filter :dropped_out

  scope :batched_and_approved, default: true
  scope :batched
  scope :inactive_for_week
  scope :endangered
  scope :all

  controller do
    def find_resource
      scoped_collection.friendly.find(params[:id])
    end
  end

  batch_action :tag, form: proc { { tag: Startup.tag_counts_on(:tags).pluck(:name) } } do |ids, inputs|
    Startup.where(id: ids).each do |startup|
      startup.tag_list.add inputs[:tag]
      startup.save!
    end

    redirect_to collection_path, alert: 'Tag added!'
  end

  index do
    selectable_column

    column :product do |startup|
      link_to startup.display_name, admin_startup_path(startup)
    end

    column :timeline_events do |startup|
      ol do
        startup.timeline_events.order('updated_at DESC').limit(5).each do |event|
          fa_icon = if event.verified?
            'fa-thumbs-o-up'
          elsif event.needs_improvement?
            'fa-star-half-empty'
          elsif event.not_accepted?
            'fa-ban'
          else
            'fa-clock-o'
          end
          li do
            link_to " #{event.title}", [:admin, event], class: "fa #{fa_icon} no-text-decoration"
          end
        end
      end
    end

    actions do |startup|
      span do
        link_to 'View Timeline', startup, target: '_blank', class: 'member_link'
      end

      span do
        link_to 'View All Feedback',
          admin_startup_feedback_index_url('q[startup_id_eq]' => startup.id, commit: 'Filter'),
          class: 'member_link'
      end

      span do
        link_to 'Record New Feedback',
          new_admin_startup_feedback_path(
            startup_feedback: {
              startup_id: startup.id,
              reference_url: startup_url(startup)
            }
          ),
          class: 'member_link'
      end
    end
  end

  csv do
    column :product_name
    column :product_description
    column :presentation_link
    column :product_video_link
    column :wireframe_link
    column :prototype_link
    column :batch
    column(:founders) { |startup| startup.founders.pluck(:name).join ', ' }
    column(:team_members) { |startup| startup.team_members.pluck(:name).join ', ' }
    column(:women_cofounders) { |startup| startup.founders.where(gender: Founder::GENDER_FEMALE).count }
    column :pitch
    column :website
    column :email
    column :registration_type
    column :district
    column :pin
    column :product_progress
    column :agreement_signed_at
  end

  action_item :view_feedback, only: :show do
    link_to(
      'View All Feedback',
      admin_startup_feedback_index_url('q[startup_id_eq]' => Startup.friendly.find(params[:id]).id, commit: 'Filter')
    )
  end

  action_item :record_feedback, only: :show do
    link_to(
      'Record New Feedback',
      new_admin_startup_feedback_path(
        startup_feedback: {
          startup_id: Startup.friendly.find(params[:id]).id,
          reference_url: startup_url(Startup.friendly.find(params[:id]))
        }
      )
    )
  end

  action_item :view_timeline, only: :show do
    link_to('View Timeline', startup_url(startup), target: '_blank')
  end

  # TODO: rewrite as its only used for dropping out startups now
  member_action :custom_update, method: :put do
    startup = Startup.friendly.find params[:id]
    startup.update_attributes!(permitted_params[:startup])

    case params[:email_to_send].to_sym
      when :dropped_out
        StartupMailer.startup_dropped_out(startup).deliver_later
      # TODO: Re-write a mail welcoming the startup back after a drop-out ?
    end

    redirect_to action: :show
  end

  member_action :get_all_startup_feedback do
    startup = Startup.friendly.find params[:id]
    feedback = startup.startup_feedback.order('updated_at desc')

    respond_to do |format|
      format.json do
        render json: { feedback: feedback, product_name: startup.product_name }
      end
    end
  end

  member_action :change_admin, method: :patch do
    Startup.transaction do
      startup = Startup.friendly.find(params[:id])

      # Remove the old admin, if any.
      startup.admin&.update!(startup_admin: nil)

      # Add the new admin.
      startup.founders.friendly.find(params[:founder_id]).update(startup_admin: true)
    end

    redirect_to action: :show
  end

  show title: :product_name do |startup|
    attributes_table do
      row :product_description do
        simple_format startup.product_description
      end

      row :legal_registered_name
      row :dropped_out do
        div class: 'startup-status' do
          startup.dropped_out
        end

        div class: 'startup-status-buttons' do
          unless startup.approved?
            span do
              button_to(
                'Approve Startup',
                custom_update_admin_startup_path(startup: { dropped_out: false }, email_to_send: :approval),
                method: :put, data: { confirm: 'Are you sure you want to approve this startup?' }
              )
            end
          end
          unless startup.dropped_out?
            span do
              button_to(
                'Drop-out Startup',
                custom_update_admin_startup_path(startup: { dropped_out: true }, email_to_send: :dropped_out),
                method: :put, data: { confirm: 'Are you sure you want to drop out this startup?' }
              )
            end
          end
        end
      end

      row :batch
      row :iteration

      row :tags do
        linked_tags(startup.tags)
      end

      row :agreement_signed_at
      row :email

      row :logo do
        link_to(image_tag(startup.logo_url(:thumb)), startup.logo_url) if startup.logo.present?
      end

      row :website

      row :presentation_link do
        link_to startup.presentation_link, startup.presentation_link if startup.presentation_link.present?
      end

      row :product_video_link do
        link_to startup.product_video_link, startup.product_video_link if startup.product_video_link.present?
      end

      row :wireframe_link do
        link_to startup.wireframe_link, startup.wireframe_link if startup.wireframe_link.present?
      end

      row :prototype_link do
        link_to startup.prototype_link, startup.prototype_link if startup.prototype_link.present?
      end

      row :startup_categories do
        startup.startup_categories.map(&:name).join(', ')
      end

      row :phone do
        startup.admin.try(:phone)
      end

      row :address
      row :district
      row :state

      row 'PIN Code' do
        startup.pin
      end

      row :facebook_link
      row :twitter_link

      row :founders do
        div do
          startup.founders.each do |founder|
            div do
              span do
                link_to founder.display_name, [:admin, founder]
              end

              span do
                " &mdash; #{link_to 'Karma++'.html_safe, new_admin_karma_point_path(karma_point: { founder_id: founder.id })}".html_safe
              end

              span do
                if founder.startup_admin?
                  " &mdash; (Current Team Lead)".html_safe
                else
                  " &mdash; #{link_to('Make Team Lead', change_admin_admin_startup_path(founder_id: founder),
                    method: :patch, data: { confirm: 'Are you sure you want to change the team lead for this startup?' })}".html_safe
                end
              end
            end
          end
        end
      end

      row :team_members do
        if startup.team_members.present?
          ul do
            startup.team_members.each do |team_member|
              li do
                link_to team_member.name, admin_team_member_path(team_member)
              end
            end
          end
        end
      end

      row :women_cofounders do
        startup.founders.where(gender: Founder::GENDER_FEMALE).count
      end

      row :registration_type
      row :address
    end
  end

  form partial: 'admin/startups/form'
end
