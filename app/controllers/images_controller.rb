class ImagesController < ApplicationController
  before_action :search_images, only: [:index, :show, :select_characters, :search, :line]
  before_action :set_image, only: [:edit, :show, :update]

  def index
  end

  def show
    @episode = Episode.where(animation_id: @image.animation_id).find_by(episode_num: @image.episode)
    @image.open_count_increment
  end

  def search
    if params[:q].nil?
      redirect_to images_path
    else
      @animation = Animation.find_by(id: params[:q][:animation_id_eq])
      @characters = Character.where(id: params[:q][:character_images_character_id_eq_any]).order("id")
      @line = params[:q][:line_or_description_cont]
      @episode = params[:q][:episode_eq]
    end
  end

  def select_animation
    @animations = Animation.all.order("id")
  end

  def select_characters
    @animation = Animation.find_by(id: params[:animation_id])
    @characters = if @animation.present?
                    Character.includes(:animations).where(animations: { id: @animation.id }).order("characters.id")
                  else
                    Character.all.order("id")
                  end
  end

  def new
    @image = Image.new
  end

  def create
    @image = Image.new(image_params)
    if @image.save
      # CreateTweetWorker.perform_async(@image.id) if Rails.env.production?
      flash[:notice] = "アップロードしました"
      SlackNotificationWorker.perform_async(@image.id)
      redirect_to edit_image_path(@image)
    else
      flash[:notice] = "アップロードに失敗しました"
      render :new
    end
  end

  def edit
  end

  def update
    if @image.update!(update_image_params)
      flash[:notice] = "更新しました"
      redirect_to edit_image_path(@image)
    else
      flash[:notice] = "更新に失敗しました"
      render :new
    end
  end

  private

    def set_params
      @character_ids = params[:character_ids]
      @animation_ids = params[:animation_ids]
      @line = params[:line]
      @episode = params[:episode]
    end

    def search_images
      @q = Image.includes(:animation, :character_images, :characters)

      # fackin relation and search
      if params[:q].present? && @character_ids = params[:q][:character_images_character_id_eq_any] && (@character_ids.size >= 2)
        images = @q.character_ids_and_search(@character_ids)
        @q = Image.where(id: images.map(&:id))
      end

      @q = @q.ransack(params[:q])

      @q.sorts = "created_at desc" if @q.sorts.empty?
      @images = @q.result(distinct: true).page(params[:page])
    end

    def set_image
      @image = Image.find(params[:id])
    end

    def image_params
      params.require(:image).permit(:image, :image_cache, :remove_image, :animation_id)
    end

    def update_image_params
      params.require(:image).permit(:image, :image_cache, :remove_image, :animation_id, :line, :description, :episode,
                                    character_ids: [])
    end
end
