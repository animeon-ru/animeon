class Api::V1::AnimesController < Api::V1Controller

  api :GET, '/animes'
  param :page, :undef, required: false
  param :page_limit, :undef, required: false
  def index
    page_limit = params[:page_limit].present? ? params[:page_limit].to_i : 25
    page = params[:page].present? ? params[:page].to_i : 1
    result = []
    Anime.all
         .order(user_rating: :desc)
         .limit(page_limit)
         .offset((page - 1) * page_limit)
         .each do |anime|
      decorator = {}
      %i[id name description episodes status user_rating franchise
      kind duration age_rating russian english japanese shiki_id
      season genres episodes_aired studio_ids].each do |s|
        decorator[s.to_sym] = anime[s.to_sym]
      end
      decorator[:poster] = anime.poster_url
      result.push decorator
    end
    render json: result, status: 200
  end

  api :GET, '/animes/search', 'Search for an anime by name or russian'
  param :name, :undef, required: true
  def search
    if (cache = Animeon::Application.redis.get("api:animes:search:#{params[:name]}")).nil?
      response = Anime.search_by_name(params[:name]).with_pg_search_rank.limit(10).select(:id, :name, :russian)
      render json: response, status: 200
      Animeon::Application.redis.set("api:animes:search:#{params[:name]}", response.to_json, ex: 86_400)
    else
      render json: JSON.parse(cache)
    end
  end
end
