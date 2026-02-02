class OngoingParserWorker
  include Sidekiq::Worker
  require 'open-uri'
  sidekiq_options queue: :ShikiParser

  def perform
    target_anime = Anime.where(status: :ongoing).order(:updated_at).first
    target_anime.update(updated_at: Time.now)
    return if target_anime.nil?

    client = Animeon::Application.shiki_api
    anime = client.v1.anime(target_anime.shiki_id).to_hash
    anime['age_rating'] = anime['rating']
    anime['user_rating'] = anime['score']
    genres_ids = []
    studio_ids = []
    anime['genres'].each do |genre|
      genres_ids << genre['id']
    end
    anime['genres'] = genres_ids
    anime['studios'].each do |studio|
      studio_ids << studio['id']
    end
    anime['studio_ids'] = studio_ids
    anime['episodes_aired'] = anime['episodes'] if anime['status'] == 'released'
    update(anime)
  end

  def update(parsed)
    anime = Anime.find_by(shiki_id: parsed['id'])
    %i[name russian episodes episodes_aired age_rating duration franchise kind].each do |key|
      next unless anime[key] != parsed[key.to_s] && parsed[key.to_s] != nil
      DbModification.new(table_name: 'Anime', row_name: key, target_id: anime.id,
                         old_data: anime[key], new_data: parsed[key.to_s],
                         status: 'approved', user_id: 1, reason: 'OngoingParserWorker update from shiki').save
    end
    %i[genres studio_ids].each do |key|
      next unless anime[key].to_a.map(&:to_i) != parsed[key.to_s].to_a.map(&:to_i) && parsed[key.to_s] != nil
      DbModification.new(table_name: 'Anime', row_name: key, target_id: anime.id,
                         old_data: anime[key], new_data: parsed[key.to_s].nil? ? '[]' : parsed[key.to_s].map(&:to_i),
                         status: 'approved', user_id: 1, reason: 'OngoingParserWorker update from shiki').save
    end
    if anime['user_rating'].to_f != parsed['user_rating'].to_f
      DbModification.new(table_name: 'Anime', row_name: 'user_rating', target_id: anime.id,
                         old_data: anime['user_rating'], new_data: parsed['user_rating'],
                         status: 'approved', user_id: 1, reason: 'OngoingParserWorker update from shiki').save
    end
  end
end
