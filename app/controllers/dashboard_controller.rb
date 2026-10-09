class DashboardController < ApplicationController
  def index
    @animes = Anime.where(status: :ongoing, kind: :tv).where("user_rating > ?", 7).limit(10).order(user_rating: :desc).shuffle[0..4]
    @animes_with_video = Anime.joins(episode: :video).distinct.limit(10).shuffle[0..4]
    @title = 'Главная страница'
    @news = News.where(is_public: true).order(public_after: :asc).limit(5)
    if @animes.empty? && @animes_with_video.empty?
      @popular = Anime.where.not(age_rating: :rx).order(user_rating: :desc).limit(12).to_a
    end
    @hero = @animes.first || @animes_with_video.first || @popular&.first
    @hero_label = if @animes.first then 'Сейчас выходит'
                  elsif @animes_with_video.first then 'Можно смотреть с озвучкой'
                  else 'Высокая оценка зрителей'
                  end
    return unless user_signed_in?

    @continue = current_user.user_rates.watching.where(target_type: 'Anime')
                            .includes(:anime).order(updated_at: :desc).limit(6)
  end
end
