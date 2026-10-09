# frozen_string_literal: true

class AnimesController < ApplicationController
  require 'open-uri'
  def index
    @animes = if params[:name].present?
                Anime.search_by_name(params[:name])
              else
                Anime.all.order(user_rating: :desc)
              end
    params.except(:controller, :action, :page, :name).each do |i|
      @animes = if i[0] == 'genres'
                  @animes.where("#{Genre.find_by(name: i[1], genre_type: 'anime').id} = ANY(genres)")
                elsif i[0] == 'studio'
                  @animes.where("#{i[1]} = ANY(studio_ids)")
                elsif i[0] == 'model'
                  @animes.joins(episode: :video).distinct
                else
                  @animes.where("#{i[0]} = '#{i[1]}'")
                end
    end
    @pagy, @animes = pagy(@animes.where.not(age_rating: :rx))
    @title = 'Все аниме'
  end

  def new
    redirect_to animes_path unless user_signed_in? && %w[admin creator].include?(current_user.role)
    @animes = Anime.new
    @title = 'Создать аниме'
  end

  def edit
    @animes = Anime.find(params[:id])
    @title = "Редактирование: #{@animes.russian.presence || @animes.name}"
  end

  def show
    @animes = Anime.find(params[:id])
    @title = @animes.name.to_s
    if user_signed_in? && UserRate.where(user_id: current_user.id, target_id: params[:id], target_type: 'Anime').empty?
      UserRate.new(user_id: current_user.id, target_id: params[:id], target_type: 'Anime', status: 6).save
    end
    return unless user_signed_in?

    @user_rate = UserRate.find_by(user_id: current_user.id, target_id: params[:id], target_type: 'Anime')
  end

  def create
    @resource = Anime.new(animes_params)
    if @resource.save
      redirect_to(@resource)
    else
      render action: 'new'
    end
  end

  def update
    @resource = Anime.find(params[:id])
    status = user_signed_as_admin? ? 'approved' : 'created'
    %w[name russian description kind status franchise age_rating].each do |key|
      if @resource[key].to_s != animes_params[key].to_s
        DbModification.new(table_name: 'Anime', row_name: key, target_id: @resource.id,
                           old_data: @resource[key], new_data: animes_params[key].nil? ? '' : animes_params[key],
                           status: status, user_id: current_user.id, reason: "#{current_user.username} edit").save
      end
    end
    %w[episodes episodes_aired user_rating duration shiki_id].each do |key|
      puts "#{@resource[key]} || #{animes_params[key]}"
      if @resource[key].to_i != animes_params[key].to_i
        DbModification.new(table_name: 'Anime', row_name: key, target_id: @resource.id,
                           old_data: @resource[key], new_data: animes_params[key].nil? ? '' : animes_params[key],
                           status: status, user_id: current_user.id, reason: "#{current_user.username} edit").save
      end
    end
    %w[genres studio_ids].each do |key|
      if @resource[key].to_a.map(&:to_i) != animes_params[key].to_a.map(&:to_i)
        DbModification.new(table_name: 'Anime', row_name: key, target_id: @resource.id,
                           old_data: @resource[key], new_data: animes_params[key].nil? ? '[]' : animes_params[key].map(&:to_i),
                           status: status, user_id: current_user.id, reason: "#{current_user.username} edit").save
      end
    end
    #animes_params.each do |key, value|
    #  puts "#{@resource[key]} || #{value}"
    #  if @resource[key].to_s != value.to_s do
    #    DbModification.new(table_name: 'Anime', row_name: key, target_id: @resource.id,
    #                       old_data: @resource[key], new_data: value,
    #                       status: 'approved', user_id: current_user.id, reason: "#{current_user.username} edit").save
    #  end
    @resource.update(poster: animes_params[:poster])
    redirect_to @resource
    #if @resource.update(animes_params)
    #
    #else
    #  render :edit, status: :unprocessable_entity
    #end
  end

  def new_from_shikimori
    @anime = Anime.new
    @title = 'Создать аниме с Shikimori API'
  end

  def create_from_shikimori
    client = Animeon::Application.shiki_api
    anime = client.v1.anime(animes_params[:shiki_id]).to_hash
    genres_ids = []
    studio_ids = []
    anime['genres'].each do |genre|
      genres_ids << genre['id']
    end
    anime['studios'].each do |studio|
      studio_ids << studio['id']
    end
    img_url = if anime['image']['original'] != '/assets/globals/missing_original.jpg'
                Paperclip.io_adapters.for(
                  URI.parse("https://shikimori.one#{anime['image']['original']}").to_s,
                  { hash_digest: Digest::MD5 }
                )
              else
                nil
              end
    @resource = Anime.new(
      name: anime['name'],
      russian: anime['russian'],
      episodes: anime['episodes'],
      episodes_aired: anime['episodes_aired'],
      age_rating: anime['rating'],
      duration: anime['duration'],
      franchise: anime['franchise'],
      user_rating: anime['score'],
      kind: anime['kind'],
      shiki_id: animes_params[:shiki_id],
      studio_ids: studio_ids,
      genres: genres_ids,
      poster: img_url
    )
    redirect_to anime_path(id: @resource.id) if @resource.save
  rescue Shikimori::API::NotFoundError
    redirect_to animes_path
  end

  def increment_episode
    redirect_back fallback_location: anime unless user_signed_in?
    anime = Anime.find(params[:anime_id])
    user_rate = current_user.user_rates.find_by(target_type: 'Anime', target_id: anime.id)
    user_rate.update(episodes: user_rate.episodes + 1) if user_signed_in? && anime.episodes > user_rate.episodes
    redirect_back fallback_location: anime
  end

  def decrement_episode
    redirect_back fallback_location: anime unless user_signed_in?
    anime = Anime.find(params[:anime_id])
    user_rate = current_user.user_rates.find_by(target_type: 'Anime', target_id: anime.id)
    user_rate.update(episodes: user_rate.episodes - 1) if user_signed_in? && user_rate.episodes.positive?
    redirect_back fallback_location: anime
  end

  def user_status
    redirect_back fallback_location: anime unless user_signed_in?
    anime = Anime.find(params[:anime_id])
    user_rate = current_user.user_rates.find_by(target_type: 'Anime', target_id: anime.id)
    params[:status] == 'completed' ? user_rate.update(status: 2, episodes: anime.episodes) : user_rate.update(status: params[:status])
    redirect_back fallback_location: anime
  end

  def information
    @resource = DbModification.where(target_id: params[:anime_id], table_name: 'Anime').order(created_at: :desc)
  end

  private

  def animes_params
    params.require(:anime).permit(:name, :russian, :description, :episodes,
                                  :episodes_aired, :kind, :status, :user_rating,
                                  :franchise, :duration, :age_rating, :poster, :shiki_id, genres: [], studio_ids: [])
  end
end
