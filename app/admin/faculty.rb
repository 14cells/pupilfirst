ActiveAdmin.register Faculty do
  include DisableIntercom

  permit_params :name, :email, :title, :key_skills, :linkedin_url, :category, :image, :sort_index, :self_service,
    :current_commitment, :founder_id, :inactive, :about, :commitment, :compensation, :slack_username, :level_id

  controller do
    def find_resource
      scoped_collection.friendly.find(params[:id])
    end
  end

  config.sort_order = 'sort_index_asc'

  filter :category, as: :select, collection: -> { Faculty.valid_categories }
  filter :name
  filter :email
  filter :title
  filter :key_skills
  filter :linkedin_url

  scope :all
  scope :recently_inactive

  index do
    selectable_column
    column :category
    column :name
    column :email
    column :level
    column :sort_index
    actions
  end

  form do |f|
    f.semantic_errors(*f.object.errors.keys)

    f.inputs 'Faculty Details' do
      f.input :category, as: :select, collection: Faculty.valid_categories
      f.input :name
      f.input :email
      f.input :level, collection: Level.where.not(number: 0)
      f.input :title
      f.input :about
      f.input :image, as: :file
      f.input :key_skills
      f.input :linkedin_url
      f.input :sort_index
      f.input :inactive
      f.input :self_service
      f.input :commitment, as: :select, collection: commitment_options, label_method: :first, value_method: :last
      f.input :current_commitment
      f.input :compensation, as: :select, collection: Faculty.valid_compensation_values
      f.input :founder
      f.input :slack_username
    end

    f.actions
  end
end
